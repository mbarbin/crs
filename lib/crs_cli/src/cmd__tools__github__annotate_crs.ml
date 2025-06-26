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
    ~summary:"Output GitHub Workflow Annotations for CRs in the repo."
    ~readme:(fun () ->
      {|
This command searches for CRs in the tree and prints GitHub Workflow Annotations for them to $(b,stdout) for use in CIs.
|})
    (let open Command.Std in
     let+ config =
       Arg.named_opt [ "config" ] Param.file ~doc:"Config file to customize crs."
     and+ review_mode = Review_mode.arg in
     let cwd = Unix.getcwd () |> Absolute_path.v in
     let { Enclosing_repo.vcs_kind = _; repo_root; vcs } =
       Common_helpers.find_enclosing_repo ~from:cwd
     in
     let config =
       match config with
       | None -> Config.empty
       | Some path -> Config.load_exn ~path:(Fpath.v path)
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
