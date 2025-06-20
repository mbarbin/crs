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

let path = Vcs.Path_in_repo.v "my_file.ml"

let parse file_contents =
  let file_contents =
    (* In this test we want to avoid test CRs to be mistaken for actual CRs,
       thus we perform some dynamic string substitutions. *)
    file_contents
    |> String.strip
    |> String.substr_replace_all ~pattern:"$CR" ~with_:"CR"
    |> String.substr_replace_all ~pattern:"$XCR" ~with_:"XCR"
    |> Vcs.File_contents.create
  in
  Crs_parser.parse_file ~path ~file_contents |> Cr_comment.sort
;;

let categorize file_contents =
  let crs = parse file_contents in
  let by_filter =
    List.map Cr_comment.Filter.all ~f:(fun filter ->
      filter, List.filter crs ~f:(fun cr -> Cr_comment.Filter.matches filter ~cr))
  in
  List.iteri by_filter ~f:(fun i (filter, crs) ->
    if i > 0 then print_endline "";
    print_endline (Printf.sprintf "====== %s" (Cr_comment.Filter.to_string filter));
    Cr_comment.print_list crs)
;;

let%expect_test "categorize" =
  categorize
    {|
(* $CR : Hey. *)

(* $CR user1: Hey. *)

(* $CR user1 for user2: Hey. *)

(* $XCR user1: Hey. *)

(* $XCR user1 for user2: Hey. *)

(* $CR-soon user1: Hey. *)

(* $CR-soon user1 for user2: Hey. *)

(* $XCR-soon user1: Hey. *)

(* $CR-someday user1: Hey. *)

(* $CR-someday user1 for user2: Hey. *)

(* $XCR-someday user1: Hey. *)
|};
  [%expect
    {|
    ====== all
    File "my_file.ml", line 1, characters 0-15:
      CR : Hey.

    File "my_file.ml", line 3, characters 0-20:
      CR user1: Hey.

    File "my_file.ml", line 5, characters 0-30:
      CR user1 for user2: Hey.

    File "my_file.ml", line 7, characters 0-21:
      XCR user1: Hey.

    File "my_file.ml", line 9, characters 0-31:
      XCR user1 for user2: Hey.

    File "my_file.ml", line 11, characters 0-25:
      CR-soon user1: Hey.

    File "my_file.ml", line 13, characters 0-35:
      CR-soon user1 for user2: Hey.

    File "my_file.ml", line 15, characters 0-26:
      XCR-soon user1: Hey.

    File "my_file.ml", line 17, characters 0-28:
      CR-someday user1: Hey.

    File "my_file.ml", line 19, characters 0-38:
      CR-someday user1 for user2: Hey.

    File "my_file.ml", lines 21-22, characters 0-29:
      XCR-someday user1: Hey.

    ====== invalid
    File "my_file.ml", line 1, characters 0-15:
      CR : Hey.

    ====== crs
    File "my_file.ml", line 3, characters 0-20:
      CR user1: Hey.

    File "my_file.ml", line 5, characters 0-30:
      CR user1 for user2: Hey.

    ====== xcrs
    File "my_file.ml", line 7, characters 0-21:
      XCR user1: Hey.

    File "my_file.ml", line 9, characters 0-31:
      XCR user1 for user2: Hey.

    File "my_file.ml", line 15, characters 0-26:
      XCR-soon user1: Hey.

    File "my_file.ml", lines 21-22, characters 0-29:
      XCR-someday user1: Hey.

    ====== now
    File "my_file.ml", line 3, characters 0-20:
      CR user1: Hey.

    File "my_file.ml", line 5, characters 0-30:
      CR user1 for user2: Hey.

    File "my_file.ml", line 7, characters 0-21:
      XCR user1: Hey.

    File "my_file.ml", line 9, characters 0-31:
      XCR user1 for user2: Hey.

    File "my_file.ml", line 15, characters 0-26:
      XCR-soon user1: Hey.

    File "my_file.ml", lines 21-22, characters 0-29:
      XCR-someday user1: Hey.

    ====== soon
    File "my_file.ml", line 11, characters 0-25:
      CR-soon user1: Hey.

    File "my_file.ml", line 13, characters 0-35:
      CR-soon user1 for user2: Hey.

    ====== someday
    File "my_file.ml", line 17, characters 0-28:
      CR-someday user1: Hey.

    File "my_file.ml", line 19, characters 0-38:
      CR-someday user1 for user2: Hey.
    |}];
  ()
;;
