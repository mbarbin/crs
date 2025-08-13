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
    ~summary:"Output Reviewdog Annotations for CRs in the repo."
    ~readme:(fun () ->
      "This command searches for CRs in the tree and prints Reviewdog Annotations for \
       them to $(b,stdout) in $(b,rdjson) format for use in CIs.")
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
       | Some path ->
         Config.load_exn ~path:(Fpath.v path) ~print_gh_annotation_warnings:true
     in
     let crs =
       Crs_parser.grep ~vcs ~repo_root ~below:Vcs.Path_in_repo.root |> Cr_comment.sort
     in
     let diagnostics =
       List.filter_map crs ~f:(fun cr ->
         Annotation.of_cr ~cr ~config ~review_mode ~with_user_mentions
         |> Option.map ~f:Annotation.to_reviewdog_diagnostic)
     in
     let diagnostic_result =
       { Reviewdog.Diagnostic_result.source = Some Reviewdog_utils.source
       ; severity = Some Info
       ; diagnostics
       }
     in
     let json = Reviewdog.Diagnostic_result.yojson_of_t diagnostic_result in
     print_endline (Yojson.Safe.pretty_to_string ~std:true json);
     ())
;;
