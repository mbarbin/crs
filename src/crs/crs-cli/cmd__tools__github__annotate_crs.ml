(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

let main =
  Command.make
    ~summary:"Output GitHub Workflow Annotations for CRs in the repo."
    ~readme:(fun () ->
      "This command searches for CRs in the tree and prints GitHub Workflow Annotations \
       for them to $(b,stdout) for use in CIs.")
    (let open Command.Std in
     let+ () = Log_cli.set_config ()
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
     let crs =
       Crs_parser.grep ~vcs ~repo_root ~below:Vcs.Path_in_repo.root |> Cr_comment.sort
     in
     List.iter crs ~f:(fun cr ->
       match
         Annotation.of_cr
           ~cr
           ~config
           ~review_mode
           ~with_user_mentions:
             (* User notifications are not supported in the context of GitHub
                Annotations. We prefer to never generate them given that they
                are going to be ignored. *)
             false
       with
       | None -> ()
       | Some annotation ->
         print_endline
           (annotation |> Annotation.to_github_annotation |> Github_annotation.to_string));
     ())
;;
