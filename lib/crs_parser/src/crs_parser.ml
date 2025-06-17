(********************************************************************************)
(*  crs - A tool for managing code review comments embedded in source code      *)
(*  Copyright (C) 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>           *)
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
      let fn = Stdlib.Filename.concat path executable_basename in
      if Stdlib.Sys.file_exists fn then Some fn else loop rest
  in
  loop (String.split path ~on:':')
;;

let find_xargs =
  lazy
    (match Stdlib.Sys.getenv_opt "PATH" with
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
  [@@deriving sexp_of]
end

let grep ~vcs ~repo_root ~below =
  let files_to_grep = Vcs.ls_files vcs ~repo_root ~below in
  let stdin_text =
    files_to_grep |> List.map ~f:Vcs.Path_in_repo.to_string |> String.concat ~sep:"\n"
  in
  let files_to_grep =
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
            ; "-r"
            ; "-d"
            ; "\n"
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
      | Unix.WEXITED (0 | 123) -> `Output stdout
      | Unix.WEXITED n -> `Exit_status (`Exited n)
      | Unix.WSIGNALED n -> `Exit_status (`Signaled n) [@coverage off]
      | Unix.WSTOPPED n -> `Exit_status (`Stopped n) [@coverage off]
    with
    | `Output stdout -> stdout |> String.split_lines |> List.map ~f:Vcs.Path_in_repo.v
    | `Exit_status exit_status ->
      let stdout = !stdout_ref in
      let stderr = !stderr_ref in
      raise
        (Err.E
           (Err.create
              [ Pp.text "Process xargs exited abnormally."
              ; Err.sexp
                  [%sexp
                    { exit_status : Exit_status.t; stdout : string; stderr : string }]
              ]))
    | exception exn ->
      raise
        (Err.E (Err.create [ Pp.text "Error while running xargs process."; Err.exn exn ]))
      [@coverage off]
  in
  List.concat_map files_to_grep ~f:(fun path_in_repo ->
    let file_contents =
      In_channel.read_all
        (Vcs.Repo_root.append repo_root path_in_repo |> Absolute_path.to_string)
      |> Vcs.File_contents.create
    in
    parse_file ~path:path_in_repo ~file_contents)
;;
