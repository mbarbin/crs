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

let filename = Fsegment.v ".crs-ignore"

module Entry = struct
  (* A compiled pattern entry for matching files. *)
  type t =
    { pattern : Re.re
    ; original_pattern : string Loc.Txt.t
    }
end

let strip_location ~file_contents ~file_cache ~loc =
  let rec strip_left start stop =
    if start >= stop
    then start
    else (
      let char = file_contents.[start] in
      match char with
      | ' ' -> strip_left (start + 1) stop
      | _ -> start)
  in
  let rec find_stop index stop =
    if index >= stop
    then stop
    else (
      let char = file_contents.[index] in
      match char with
      | '#' -> index
      | _ -> find_stop (index + 1) stop)
  in
  let rec strip_right start stop =
    if start >= stop
    then stop
    else (
      let char = file_contents.[stop - 1] in
      match char with
      | ' ' -> strip_right start (stop - 1)
      | _ -> stop)
  in
  let start = Loc.start_offset loc in
  let stop = find_stop start (Loc.stop_offset loc) in
  let start = strip_left start stop in
  let stop = strip_right start stop in
  let str = String.sub file_contents ~pos:start ~len:(stop - start) in
  { Loc.Txt.txt = str
  ; loc =
      Loc.of_lexbuf_loc
        { start = Loc.Offset.to_position start ~file_cache
        ; stop = Loc.Offset.to_position stop ~file_cache
        }
  }
;;

(* Parse and compile a single pattern line *)
let parse_and_compile_pattern
      ~file_contents
      ~file_cache
      ~line
      ~whole_line
      ~invalid_patterns_are_errors
      ~emit_github_annotations
  =
  let whole_line_loc = Loc.of_file_line ~file_cache ~line in
  let ({ Loc.Txt.txt; loc } as original_pattern) =
    strip_location ~file_contents ~file_cache ~loc:whole_line_loc
  in
  let () =
    let str =
      let str =
        match String.lsplit2 whole_line ~on:'#' with
        | None -> whole_line
        | Some (pat, _comment) -> pat
      in
      String.strip str
    in
    if not (String.equal str txt)
    then
      Err.raise
        ~loc
        [ Pp.textf "Invalid computation of position - pattern = %S" str ] [@coverage off]
  in
  if String.is_empty txt
  then None
  else (
    try
      (* Compile the glob pattern using Re.Glob, similar to ocamlformat *)
      let pattern =
        let pathname = true
        and anchored = true in
        let pattern_str =
          if Sys.win32
          then
            (* Use only forward slashes in the pattern for Windows compatibility *)
            String.concat ~sep:"/" (String.split txt ~on:'\\') [@coverage off]
          else txt
        in
        Re.(
          Glob.glob ~pathname ~anchored ~match_backslashes:Sys.win32 pattern_str
          |> compile)
      in
      Some { Entry.pattern; original_pattern }
    with
    | Re.Glob.Parse_error ->
      (if invalid_patterns_are_errors then User_message.error else User_message.warning)
        ~loc
        ~emit_github_annotations
        [ Pp.text "Invalid glob pattern:"; Pp.text txt ];
      None)
;;

module File = struct
  type t =
    { directory : Relative_path.t
    ; entries : Entry.t list
    }

  (* Load a single .crs-ignore file and return compiled patterns *)
  let parse_exn
        ~repo_root
        ~path
        ~file_contents
        ~invalid_patterns_are_errors
        ~emit_github_annotations
    =
    let directory =
      Vcs.Path_in_repo.to_relative_path path
      |> Relative_path.parent
      |> Option.value ~default:Relative_path.empty
      |> Relative_path.to_dir_path
    in
    let ignore_file_path = Vcs.Repo_root.append repo_root path in
    let file_contents = file_contents |> Vcs.File_contents.to_string in
    let file_cache =
      Loc.File_cache.create ~path:(ignore_file_path :> Fpath.t) ~file_contents
    in
    let entries =
      List.filter_mapi (String.split_lines file_contents) ~f:(fun i whole_line ->
        parse_and_compile_pattern
          ~file_contents
          ~file_cache
          ~line:(i + 1)
          ~whole_line
          ~invalid_patterns_are_errors
          ~emit_github_annotations)
    in
    { directory; entries }
  ;;

  let load_exn ~repo_root ~path ~invalid_patterns_are_errors ~emit_github_annotations =
    let ignore_file_path = Vcs.Repo_root.append repo_root path in
    let ignore_file_str = Absolute_path.to_string ignore_file_path in
    let file_contents =
      In_channel.with_open_bin ignore_file_str In_channel.input_all
      |> Vcs.File_contents.create
    in
    parse_exn
      ~repo_root
      ~path
      ~file_contents
      ~invalid_patterns_are_errors
      ~emit_github_annotations
  ;;
end

module Rules = struct
  module Marked_entry = struct
    type t =
      { entry : Entry.t
      ; mutable used : bool
      }

    let create entry = { entry; used = false }
  end

  module One_file = struct
    type t =
      { directory : Relative_path.t
      ; entries : Marked_entry.t list
      }

    let is_file_ignored t ~path =
      match Relative_path.chop_prefix ~prefix:t.directory path with
      | None ->
        (* File is not in the same directory, thus it is not ignored by the
           patterns of this file. This execution path is currently not exercised
           because we only visit [.crs-ignore] files that are in an ancestor
           position compared to [path]. *)
        false
        [@coverage off]
      | Some path ->
        let path = Relative_path.to_string path in
        List.exists t.entries ~f:(fun entry ->
          if Re.execp entry.entry.pattern path
          then (
            entry.used <- true;
            true)
          else false)
    ;;

    let create ({ directory; entries } : File.t) =
      { directory; entries = List.map entries ~f:Marked_entry.create }
    ;;
  end

  module Path_table = Hashtbl.Make (Relative_path)

  (* All the crs-ignore files, indexed by their directory. *)
  type t = { files_by_dir : One_file.t Path_table.t }

  let create files =
    (* This would raise if several files have the same directory, but this
       shouldn't happen since they all have the same basename. *)
    let files_by_dir =
      List.map files ~f:(fun (t : File.t) -> t.directory, One_file.create t)
      |> List.to_seq
      |> Path_table.of_seq
    in
    { files_by_dir }
  ;;

  let aux_dir (t : t) ~dir ~path =
    match Path_table.find_opt t.files_by_dir dir with
    | None -> false
    | Some file -> One_file.is_file_ignored file ~path
  ;;

  let strict_parent dir =
    if Relative_path.equal dir Relative_path.empty then None else Relative_path.parent dir
  ;;

  let is_file_ignored (t : t) ~path =
    let path = Vcs.Path_in_repo.to_relative_path path in
    let rec aux dir =
      match strict_parent dir with
      | None -> aux_dir t ~dir:Relative_path.empty ~path
      | Some dir -> aux_dir t ~dir ~path || aux dir
    in
    aux path
  ;;

  let unused_patterns t =
    t.files_by_dir
    |> Path_table.to_seq
    |> List.of_seq
    |> List.map ~f:(fun (_, { One_file.directory; entries }) ->
      let entries = List.filter entries ~f:(fun entry -> not entry.used) in
      { One_file.directory; entries })
    |> List.sort ~compare:(fun (f1 : One_file.t) f2 ->
      Relative_path.compare f1.directory f2.directory)
    |> List.concat_map ~f:(fun (f : One_file.t) ->
      List.map f.entries ~f:(fun entry -> entry.entry.original_pattern))
  ;;
end

module Private = struct
  module File = File
end
