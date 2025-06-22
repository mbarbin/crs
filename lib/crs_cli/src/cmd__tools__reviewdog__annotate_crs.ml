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
      {|
This command searches for CRs in the tree and prints Reviewdog Annotations for them to $(b,stdout) in $(rdfjson) format for use in CIs.
|})
    (let open Command.Std in
     let+ () = Arg.return () in
     let cwd = Unix.getcwd () |> Absolute_path.v in
     let { Enclosing_repo.vcs_kind = _; repo_root; vcs } =
       Common_helpers.find_enclosing_repo ~from:cwd
     in
     let crs =
       Crs_parser.grep ~vcs ~repo_root ~below:Vcs.Path_in_repo.root |> Cr_comment.sort
     in
     List.iter crs ~f:(fun cr ->
       match Cr_comment.work_on cr with
       | Soon | Someday -> ()
       | Now ->
         let level =
           match Cr_comment.header cr with
           | Error _ -> `Invalid
           | Ok _ -> `Now
         in
         let annotation =
           match level with
           | `Invalid -> "warning"
           | `Now -> "notice"
         in
         let title =
           match level with
           | `Invalid -> "Invalid CR"
           | `Now -> "Pending CR"
         in
         let message =
           match level with
           | `Invalid -> "This CR is not well formatted. Please attend."
           | `Now -> "This CR is pending. Please attend."
         in
         let start_pos = Cr_comment.whole_loc cr |> Loc.start in
         print_endline
           (Printf.sprintf
              "::%s file=%s,line=%d,col=%d,title=%s::%s"
              annotation
              (Vcs.Path_in_repo.to_string (Cr_comment.path cr))
              start_pos.pos_lnum
              (start_pos.pos_cnum - start_pos.pos_bol + 1)
              title
              message);
         ());
     ())
;;
