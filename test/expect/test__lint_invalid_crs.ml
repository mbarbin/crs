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

(* In this test we demonstrate how to use some functionality we have in place to
   parse invalid CRs, and how this could be used by a linter that would use some
   heuristics to propose suggestions to make the CRs valid.

   Note, at this stage this is more or less a proof of concept to get started,
   but we hope we'll be able to attend incrementally. *)

module Invalid_cr_parser = Crs_parser.Private.Invalid_cr_parser

let path = Vcs.Path_in_repo.v "my_file.ml"

let test file_contents ~f =
  Tests_helpers.test ~path ~file_contents ~f:(fun ~crs ~file_rewriter ->
    let file_cache =
      Loc.File_cache.create
        ~path:(Vcs.Path_in_repo.to_relative_path path :> Fpath.t)
        ~file_contents:(File_rewriter.original_contents file_rewriter)
    in
    List.iter crs ~f:(fun cr ->
      match Cr_comment.header cr with
      | Ok _ -> () (* In this test we only care about invalid CRs. *)
      | Error _ ->
        (match
           Invalid_cr_parser.parse
             ~file_cache
             ~content_start_offset:(Cr_comment.content_start_offset cr)
             ~content:(Cr_comment.content cr)
         with
         | Not_a_cr -> ()
         | Invalid_cr cr -> f cr ~file_rewriter)))
;;

let%expect_test "fix-for-or-to typo" =
  let file_contents =
    {|
let () =
  (* $CR *)
  ()
;;

let () =
  (* $CR user: This a valid one. *)
  ()
;;

let () =
  (* $CR user1 to user2: This comment is for you and it is addressed to you. *)
  ()
;;
|}
  in
  test file_contents ~f:(fun cr ~file_rewriter ->
    Option.iter (Invalid_cr_parser.Invalid_cr.for_or_to cr) ~f:(fun for_or_to ->
      if not (String.equal for_or_to.txt "for")
      then
        File_rewriter.replace file_rewriter ~range:(Loc.range for_or_to.loc) ~text:"for"));
  [%expect
    {|
    -1,15 +1,15

      let () =
        (* $CR *)
        ()
      ;;

      let () =
        (* $CR user: This a valid one. *)
        ()
      ;;

      let () =
    -|  (* $CR user1 to user2: This comment is for you and it is addressed to you. *)
    +|  (* $CR user1 for user2: This comment is for you and it is addressed to you. *)
        ()
      ;;
    |}];
  ()
;;
