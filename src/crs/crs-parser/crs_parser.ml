(********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code    *)
(*  Copyright (C) 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>           *)
(*                                                                              *)
(*  This file is part of crs.                                                   *)
(*                                                                              *)
(*  crs is free software; you can redistribute it and/or modify it under the    *)
(*  terms of the GNU Lesser General Public License as published by the Free     *)
(*  Software Foundation either version 3 of the License, or any later version,  *)
(*  with the LGPL-3.0 Linking Exception.                                        *)
(*                                                                              *)
(*  crs is distributed in the hope that it will be useful, but WITHOUT ANY      *)
(*  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS   *)
(*  FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License and     *)
(*  the file `NOTICE.md` at the root of this repository for more details.       *)
(*                                                                              *)
(*  You should have received a copy of the GNU Lesser General Public License    *)
(*  and the LGPL-3.0 Linking Exception along with this library. If not, see     *)
(*  <http://www.gnu.org/licenses/> and <https://spdx.org>, respectively.        *)
(********************************************************************************)

(* This module is derived from Iron (v0.9.114.44+47), file
 * [./hg/cr_comment.ml], which is released under Apache 2.0:
 *
 * Copyright (c) 2016-2017 Jane Street Group, LLC <opensource-contacts@janestreet.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy
 * of the License at:
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations
 * under the License.
 *
 * See the file `NOTICE.md` at the root of this repository for more details.
 *
 * Changes:
 *
 * - Migrate to this file only the part that relates to grepping versioned files.
 * - Remove dependency to [Core] - make small adjustments to use [Base] instead.
 * - Remove dependency to [Async] - replace by [Spawn] and [Stdio].
 * - Use [Vcs] instead of [Hg].
 *)

module Unix = UnixLabels

let cr_pattern_egrep = File_parser.cr_pattern_egrep
let parse_file = File_parser.parse_file

let rec waitpid_non_intr pid =
  try Unix.waitpid ~mode:[] pid with
  | Unix.Unix_error (EINTR, _, _) -> waitpid_non_intr pid [@coverage off]
;;

let read_all_from_fd fd =
  let out = In_channel.input_all (Unix.in_channel_of_descr fd) in
  Unix.close fd;
  out
;;

let find_executable ~path ~executable_basename =
  let rec loop = function
    | [] -> (None [@coverage off])
    | path :: rest ->
      let fn = Filename.concat path executable_basename in
      if Sys.file_exists fn then Some fn else loop rest
  in
  loop (String.split path ~on:':')
;;

let find_xargs =
  lazy
    (match Sys.getenv_opt "PATH" with
     | None -> None [@coverage off]
     | Some path -> find_executable ~path ~executable_basename:"xargs")
;;

module Exit_status = struct
  [@@@coverage off]

  type t =
    [ `Exited of int
    | `Signaled of int
    | `Stopped of int
    ]

  let to_dyn : t -> Dyn.t = function
    | `Exited i -> Dyn.variant "Exited" [ Dyn.int i ]
    | `Signaled i -> Dyn.variant "Signaled" [ Dyn.int i ]
    | `Stopped i -> Dyn.variant "Stopped" [ Dyn.int i ]
  ;;
end

let null_separator = String.make 1 (Char.chr 0)

let () =
  (* Something similar is done when you link with [Core_unix] however it is
     preferable to make the rendering of errors deterministic based on code
     present in this module here rather than purely from dependencies, since
     dependencies may change. *)
  Sexplib0.Sexp_conv.Exn_converter.add [%extension_constructor Unix.Unix_error] (function
    | Unix.Unix_error (error, fn, param) ->
      Sexplib0.Sexp.List
        [ Atom "Unix.Unix_error"; Atom (Unix.error_message error); Atom fn; Atom param ]
    | _ -> assert false)
;;

let grep ~vcs ~repo_root ~below =
  match Vcs.ls_files vcs ~repo_root ~below with
  | [] -> []
  | _ :: _ as files_below ->
    let files_to_grep =
      let stdin_text =
        files_below
        |> List.map ~f:Vcs.Path_in_repo.to_string
        |> String.concat ~sep:null_separator
      in
      let stdout_ref = ref "<Unknown>" in
      let stderr_ref = ref "<Unknown>" in
      match
        let prog =
          match Lazy.force find_xargs with
          | Some prog -> prog
          | None -> failwith "Cannot find xargs in PATH" [@coverage off]
        in
        let stdin_reader, stdin_writer = Spawn.safe_pipe () in
        let stdout_reader, stdout_writer = Spawn.safe_pipe () in
        let stderr_reader, stderr_writer = Spawn.safe_pipe () in
        let pid =
          Spawn.spawn
            ~cwd:(Path (Vcs.Repo_root.to_string repo_root))
            ~prog
            ~argv:
              [ "xargs"
              ; "-0"
              ; "grep"
              ; "--no-messages"
              ; "-E"
              ; "-l"
              ; "--binary-files=without-match"
              ; cr_pattern_egrep
              ]
            ~stdin:stdin_reader
            ~stdout:stdout_writer
            ~stderr:stderr_writer
            ()
        in
        Unix.close stdin_reader;
        Unix.close stdout_writer;
        Unix.close stderr_writer;
        let () =
          let stdin_oc = Unix.out_channel_of_descr stdin_writer in
          Out_channel.output_string stdin_oc stdin_text;
          Out_channel.flush stdin_oc;
          Unix.close stdin_writer
        in
        let stdout = read_all_from_fd stdout_reader in
        stdout_ref := stdout;
        let stderr = read_all_from_fd stderr_reader in
        stderr_ref := stderr;
        let pid', process_status = waitpid_non_intr pid in
        assert (pid = pid');
        match process_status with
        | Unix.WEXITED n ->
          (* The exit code of [xargs] is not consistent on all of the platforms
             that we'd like to support. While it always returns [0] in case of
             a match, when the inner [grep] doesn't find a match and returns
             [1], the outer call to [xargs] may return [1] or [123] depending
             on things like the OS. *)
          if
            Int.equal n 0
            || ((Int.equal n 123 || Int.equal n 1 (* On MacOS *))
                && String.is_empty stderr)
          then (
            let files = stdout |> String.split_lines |> List.map ~f:Vcs.Path_in_repo.v in
            `Files files)
          else `Error (`Exited n)
        | Unix.WSIGNALED n -> `Error (`Signaled n) [@coverage off]
        | Unix.WSTOPPED n -> `Error (`Stopped n) [@coverage off]
      with
      | `Files files -> files
      | `Error exit_status ->
        let stdout = !stdout_ref in
        let stderr = !stderr_ref in
        raise
          (Err.E
             (Err.create
                [ Pp.text "Process xargs exited abnormally."
                ; Dyn.pp
                    (Dyn.record
                       [ "exit_status", exit_status |> Exit_status.to_dyn
                       ; "stdout", stdout |> Dyn.string
                       ; "stderr", stderr |> Dyn.string
                       ])
                ]))
      | exception exn ->
        raise
          (Err.E
             (Err.create [ Pp.text "Error while running xargs process."; Err.exn exn ]))
        [@coverage off]
    in
    (match files_to_grep with
     | [] -> []
     | _ :: _ ->
       let crs_ignore_rules =
         let filename = Fsegment.to_string Crs_ignore.filename in
         let crs_ignore_files =
           let files_in_repo =
             if Vcs.Path_in_repo.equal below Vcs.Path_in_repo.root
             then files_below
             else Vcs.ls_files vcs ~repo_root ~below:Vcs.Path_in_repo.root
           in
           List.filter files_in_repo ~f:(fun file ->
             String.equal filename (Fpath.basename (Vcs.Path_in_repo.to_fpath file)))
         in
         List.map crs_ignore_files ~f:(fun path ->
           Crs_ignore.File.load_exn
             ~repo_root
             ~path
             ~invalid_patterns_are_errors:false
             ~emit_github_annotations:false)
         |> Crs_ignore.Rules.create
       in
       List.concat_map files_to_grep ~f:(fun path ->
         if Crs_ignore.Rules.is_file_ignored crs_ignore_rules ~path
         then []
         else (
           let file_contents =
             In_channel.with_open_bin
               (Vcs.Repo_root.append repo_root path |> Absolute_path.to_string)
               In_channel.input_all
             |> Vcs.File_contents.create
           in
           parse_file ~path ~file_contents)))
;;

module Private = struct
  module Std = struct
    module Crs_ignore = Crs_ignore
    module Github_annotation = Github_annotation
    module Invalid_cr_parser = Invalid_cr_parser
    module Invalid_cr = Invalid_cr_parser.Invalid_cr
    module User_message = User_message
  end
end
