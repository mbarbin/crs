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

let main =
  Command.make
    ~summary:"Print a comment with a summary of CRs in the repo."
    ~readme:(fun () ->
      {|
This command searches for CRs in the tree and prints a summary using the GitHub Flavored Markdown syntax.

This command is meant to be used to generate contents to include to the history of a pull request on GitHub, for example in conversation comments or checks panels.
|})
    (let open Command.Std in
     let+ with_user_mentions = Common_helpers.with_user_mentions_arg
     and+ config =
       Arg.named_opt [ "config" ] Param.file ~doc:"Config file to customize crs."
     and+ review_mode = Review_mode.arg ~print_gh_annotation_warnings:true in
     let cwd = Unix.getcwd () |> Absolute_path.v in
     let { Enclosing_repo.vcs_kind = _; repo_root; vcs } =
       Common_helpers.find_enclosing_repo ~from:cwd
     in
     let config =
       match config with
       | None -> Config.empty
       | Some path -> Config.load_exn ~path:(Fpath.v path)
     in
     let annotated_crs =
       Crs_parser.grep ~vcs ~repo_root ~below:Vcs.Path_in_repo.root
       |> Cr_comment.sort
       |> List.filter_map ~f:(fun cr ->
         match Annotation.of_cr ~cr ~config ~review_mode ~with_user_mentions with
         | None -> None
         | Some annotation -> Some (cr, annotation))
     in
     let crs, annotations = List.unzip annotated_crs in
     let by_type =
       Summary_table.By_type.make crs |> Summary_table.By_type.to_print_table
     in
     let summary = Summary_table.make crs |> Summary_table.to_print_table in
     let tables =
       List.filter_opt [ by_type; summary ]
       |> List.map ~f:Print_table.to_string_markdown
       |> String.concat ~sep:"\n"
     in
     let assignees =
       List.filter_map annotations ~f:(fun t ->
         let assignee = (Annotation.assignee t).user in
         match assignee with
         | None -> None
         | Some user -> Some (user, t))
       |> List.Assoc.sort_and_group ~compare:Vcs.User_handle.compare
       |> List.map ~f:(fun (user, ts) ->
         let with_user_mention = List.exists ts ~f:Annotation.with_user_mention in
         Annotation.write_username ~user ~with_user_mention)
     in
     print_endline tables;
     let () =
       if not (List.is_empty assignees)
       then
         print_endline
           (Printf.sprintf
              "Users with assigned CRs/XCRs: %s"
              (String.concat ~sep:", " assignees))
     in
     ())
;;
