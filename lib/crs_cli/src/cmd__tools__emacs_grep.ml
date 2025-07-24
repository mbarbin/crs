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

module Path_display_mode = struct
  type t =
    | Absolute
    | Relative_to_repo_root
    | Relative_to_cwd
  [@@deriving enumerate]

  let to_string = function
    | Absolute -> "absolute"
    | Relative_to_repo_root -> "relative-to-repo-root"
    | Relative_to_cwd -> "relative-to-cwd"
  ;;
end

let loc_to_string loc ~repo_root ~below ~path_display_mode =
  let loc = (Loc.to_lexbuf_loc loc).start in
  let fname = Vcs.Path_in_repo.v loc.pos_fname in
  let path =
    match (path_display_mode : Path_display_mode.t) with
    | Absolute ->
      (Vcs.Repo_root.append repo_root fname |> Absolute_path.to_string) [@coverage off]
    | Relative_to_cwd ->
      (match
         Relative_path.chop_prefix (Vcs.Path_in_repo.to_relative_path fname) ~prefix:below
       with
       | Some path -> Printf.sprintf "./%s" (Relative_path.to_string path)
       | None -> Printf.sprintf "./%s" (Vcs.Path_in_repo.to_string fname))
    | Relative_to_repo_root -> Printf.sprintf "./%s" (Vcs.Path_in_repo.to_string fname)
  in
  Printf.sprintf "%s:%d:" path loc.pos_lnum
;;

let to_string t ~repo_root ~below ~path_display_mode =
  String.concat
    ~sep:"\n"
    [ loc_to_string (Cr_comment.whole_loc t) ~repo_root ~below ~path_display_mode
    ; Cr_comment.reindented_content t ~new_line_prefix:"  "
    ; ""
    ]
;;

let output_one ~include_delim cr ~oc ~repo_root ~below ~path_display_mode =
  let str = to_string cr ~repo_root ~below ~path_display_mode in
  let nl = if include_delim then "\n" else "" in
  Out_channel.output_string oc (Printf.sprintf "%s%s" nl str)
;;

let output_list crs ~oc ~repo_root ~below ~path_display_mode =
  let crs = Cr_comment.sort crs in
  let include_delim = ref false in
  List.iter crs ~f:(fun cr ->
    output_one ~include_delim:!include_delim cr ~oc ~repo_root ~below ~path_display_mode;
    include_delim := true)
;;

let main =
  Command.make
    ~summary:"A util for emacs crs-grep-mode to search CRs."
    ~readme:(fun () ->
      {|
This command is a building block to the emacs $(b,crs-grep-mode).

It first locates the repository in which the command is launched and then grep-finds all CRs located in listed-files located in the subtree whose root is the current working directory of the command.

It then prints these CRs to $(b,stdout), displaying paths using a syntax that facilitate the integration with emacs grep-mode.

By default the file paths are displayed relative to the command's $(b,cwd).
|})
    (let open Command.Std in
     let+ path_display_mode =
       Arg.named_with_default
         [ "path-display-mode" ]
         (Param.enumerated (module Path_display_mode))
         ~docv:"MODE"
         ~doc:"Specify how the paths are displayed."
         ~default:Relative_to_cwd
     and+ summary =
       Arg.flag
         [ "summary" ]
         ~doc:"Print CR counts in summary tables instead of listing each CR."
     and+ filters = Common_helpers.filters in
     let cwd = Unix.getcwd () |> Absolute_path.v in
     let { Enclosing_repo.vcs_kind = _; repo_root; vcs } =
       Common_helpers.find_enclosing_repo ~from:cwd
     in
     let below =
       Common_helpers.relativize ~repo_root ~cwd ~path:(Relative_path.empty :> Fpath.t)
     in
     let crs =
       let all_crs = Crs_parser.grep ~vcs ~repo_root ~below in
       match filters with
       | `All -> all_crs
       | `Only filters ->
         List.filter all_crs ~f:(fun cr ->
           List.exists filters ~f:(fun filter -> Cr_comment.Filter.matches filter ~cr))
     in
     if summary
     then (
       let by_type =
         Summary_table.By_type.make crs |> Summary_table.By_type.to_print_table
       in
       let summary = Summary_table.make crs |> Summary_table.to_print_table in
       let tables =
         List.filter_opt [ by_type; summary ]
         |> List.map ~f:Print_table.to_string_text
         |> String.concat ~sep:"\n"
       in
       Out_channel.output_string Stdio.stdout tables)
     else
       output_list
         crs
         ~oc:Out_channel.stdout
         ~repo_root
         ~below:(Vcs.Path_in_repo.to_relative_path below)
         ~path_display_mode)
;;
