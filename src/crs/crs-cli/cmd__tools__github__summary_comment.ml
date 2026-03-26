(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

let main =
  Command.make
    ~summary:"Print a comment with a summary of CRs in the repo."
    ~readme:(fun () ->
      "This command searches for CRs in the tree and prints a summary using the GitHub \
       Flavored Markdown syntax.\n\n\
       This command is meant to be used to generate contents to include to the history \
       of a pull request on GitHub, for example in conversation comments or checks \
       panels.")
    (let open Command.Std in
     let+ () = Log_cli.set_config ()
     and+ with_user_mentions = Common_helpers.with_user_mentions_arg
     and+ config =
       Arg.named_opt [ "config" ] Param.file ~doc:"Config file to customize crs."
     and+ review_mode = Review_mode.arg ~emit_github_annotations:true in
     let cwd = Unix.getcwd () |> Absolute_path.v in
     let { Enclosing_repo.vcs_kind = _; repo_root; vcs } =
       Common_helpers.find_enclosing_repo ~from:cwd
     in
     let config =
       match config with
       | None -> Config.empty
       | Some path -> Config.load_exn ~path:(Fpath.v path) ~emit_github_annotations:true
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
       |> List.sort_and_group ~compare:(fun (u1, _) (u2, _) -> User_handle.compare u1 u2)
       |> List.filter_map ~f:(function
         | [] -> assert false (* groups are non empty. *)
         | (user, _) :: _ as all -> Some (user, List.map all ~f:snd))
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
