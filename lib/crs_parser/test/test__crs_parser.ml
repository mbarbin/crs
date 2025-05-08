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

let test file_contents =
  let file_contents =
    (* In this test we want to avoid test CRs to be mistaken for actual CRs,
       thus we perform some dynamic string substitutions. *)
    file_contents
    |> String.strip
    |> String.substr_replace_all ~pattern:"$CR" ~with_:"CR"
    |> String.substr_replace_all ~pattern:"$XCR" ~with_:"XCR"
    |> Vcs.File_contents.create
  in
  let crs = Crs_parser.parse_file ~path ~file_contents in
  List.iter crs ~f:(fun t ->
    Ref.set_temporarily Loc.include_sexp_of_locs true ~f:(fun () ->
      print_s [%sexp (t : Cr_comment.t)]))
;;

let%expect_test "non commented CR" =
  test
    {|
$CR user1: message.
|};
  [%expect {||}];
  ()
;;

let%expect_test "invalid syntax CR" =
  test
    {|
(* $CR *)
|};
  [%expect
    {|
    ((path my_file.ml)
     (whole_loc (
       (start my_file.ml:1:0)
       (stop  my_file.ml:2:0)))
     (header (Error ("Invalid CR comment" "CR ")))
     (digest_of_condensed_content 2df7d9b304674cd4ce376be6534aa33c)
     (content "CR "))
    |}];
  ()
;;

let%expect_test "empty CR" =
  test
    {|
(* $CR user: *)
|};
  [%expect
    {|
    ((path my_file.ml)
     (whole_loc (
       (start my_file.ml:1:0)
       (stop  my_file.ml:2:0)))
     (header (
       Ok (
         (kind (
           (txt CR)
           (loc (
             (start my_file.ml:1:3)
             (stop  my_file.ml:1:5)))))
         (due (
           (txt Now)
           (loc (
             (start my_file.ml:1:3)
             (stop  my_file.ml:1:5)))))
         (reported_by (
           (txt user)
           (loc (
             (start my_file.ml:1:6)
             (stop  my_file.ml:1:10)))))
         (for_ ()))))
     (digest_of_condensed_content 24aa6eaab5d3e6bdbad82e1d3c30ee5c)
     (content "CR user: "))
    |}];
  ()
;;

let%expect_test "CR soon, someday" =
  test
    {|
(* $CR-soon user: Some text *)
let () = ()
(* $CR-someday user: Some text *)
|};
  [%expect
    {|
    ((path my_file.ml)
     (whole_loc (
       (start my_file.ml:1:0)
       (stop  my_file.ml:1:29)))
     (header (
       Ok (
         (kind (
           (txt CR)
           (loc (
             (start my_file.ml:1:3)
             (stop  my_file.ml:1:5)))))
         (due (
           (txt Soon)
           (loc (
             (start my_file.ml:1:6)
             (stop  my_file.ml:1:10)))))
         (reported_by (
           (txt user)
           (loc (
             (start my_file.ml:1:11)
             (stop  my_file.ml:1:15)))))
         (for_ ()))))
     (digest_of_condensed_content 4219a06e2fd5ff693e3b986894502550)
     (content "CR-soon user: Some text "))
    ((path my_file.ml)
     (whole_loc (
       (start my_file.ml:3:0)
       (stop  my_file.ml:4:0)))
     (header (
       Ok (
         (kind (
           (txt CR)
           (loc (
             (start my_file.ml:3:3)
             (stop  my_file.ml:3:5)))))
         (due (
           (txt Someday)
           (loc (
             (start my_file.ml:3:6)
             (stop  my_file.ml:3:13)))))
         (reported_by (
           (txt user)
           (loc (
             (start my_file.ml:3:14)
             (stop  my_file.ml:3:18)))))
         (for_ ()))))
     (digest_of_condensed_content a195a2478aff6278dcf18f5c7d690323)
     (content "CR-someday user: Some text "))
    |}];
  ()
;;

let%expect_test "Dated CRs" =
  (* This is an older use case that allowed dates in CRs. Keeping as monitoring
     test for now - whether to keep supporting this functionality is to be
     determined and left as future work. *)
  test
    {|
(* $CR-2026-01-31 user: This CR has a due date, by not correctly specified. *)
let () = ()

(* $CR-20260131 user: This is not it either.. *)
let () = ()

(* $CR-202601 user: You would presumably only include the year and month. *)
let () = ()

|};
  [%expect
    {|
    ((path my_file.ml)
     (whole_loc (
       (start my_file.ml:1:0)
       (stop  my_file.ml:1:77)))
     (header (
       Error (
         "Invalid CR comment"
         "CR-2026-01-31 user: This CR has a due date, by not correctly specified. ")))
     (digest_of_condensed_content 1f9be944b3383d5ee336d876ec1a0568)
     (content
      "CR-2026-01-31 user: This CR has a due date, by not correctly specified. "))
    ((path my_file.ml)
     (whole_loc (
       (start my_file.ml:4:0)
       (stop  my_file.ml:4:47)))
     (header (
       Error ("Invalid CR comment" "CR-20260131 user: This is not it either.. ")))
     (digest_of_condensed_content 268498d73e27329e7a10a2740442d95f)
     (content "CR-20260131 user: This is not it either.. "))
    ((path my_file.ml)
     (whole_loc (
       (start my_file.ml:7:0)
       (stop  my_file.ml:7:75)))
     (header (
       Ok (
         (kind (
           (txt CR)
           (loc (
             (start my_file.ml:7:3)
             (stop  my_file.ml:7:5)))))
         (due (
           (txt Someday)
           (loc (
             (start my_file.ml:7:6)
             (stop  my_file.ml:7:12)))))
         (reported_by (
           (txt user)
           (loc (
             (start my_file.ml:7:13)
             (stop  my_file.ml:7:17)))))
         (for_ ()))))
     (digest_of_condensed_content cc821c3436b2583715a2df4236a786c4)
     (content
      "CR-202601 user: You would presumably only include the year and month. "))
    |}];
  ()
;;

let%expect_test "indentation" =
  let parse file_contents =
    let file_contents =
      file_contents
      |> String.strip
      |> String.substr_replace_all ~pattern:"$CR" ~with_:"CR"
      |> String.substr_replace_all ~pattern:"$XCR" ~with_:"XCR"
      |> Vcs.File_contents.create
    in
    Crs_parser.parse_file ~path ~file_contents
  in
  let crs1 =
    parse
      {|
let f () =
  (* $CR user1: We want to be able to compute a digest for the message that is stable across
     indentation changes such as across a refactoring. *)
  ()
|}
  in
  let crs2 =
    parse
      {|
module F = struct
  let f () =
    (* $CR user1: We want to be able to compute a digest for the message that is stable
       across indentation changes such as across a refactoring. *)
    ()
end
|}
  in
  let cr1 = List.hd_exn crs1 in
  let cr2 = List.hd_exn crs2 in
  let d1 = Cr_comment.digest_ignoring_minor_text_changes cr1 in
  require_equal
    [%here]
    (module Cr_comment.Digest_hex)
    (Cr_comment.digest_ignoring_minor_text_changes cr1)
    (Cr_comment.digest_ignoring_minor_text_changes cr2);
  print_endline (Cr_comment.Digest_hex.to_string d1);
  [%expect {| 531e26a81b7ffd0477a38b97f63c81fa |}];
  Expect_test_patdiff.print_patdiff_s
    [%sexp (cr1 : Cr_comment.t)]
    [%sexp (cr2 : Cr_comment.t)];
  [%expect
    {|
    -1,11 +1,11
      ((path      my_file.ml)
       (whole_loc _)
       (header (
         Ok (
           (kind        CR)
           (due         Now)
           (reported_by user1)
           (for_ ()))))
       (digest_of_condensed_content 531e26a81b7ffd0477a38b97f63c81fa)
       (content
    -|  "CR user1: We want to be able to compute a digest for the message that is stable across\n     indentation changes such as across a refactoring. "))
    +|  "CR user1: We want to be able to compute a digest for the message that is stable\n       across indentation changes such as across a refactoring. "))
    |}];
  let cr1_reindented = Cr_comment.to_string cr1 in
  let cr2_reindented = Cr_comment.to_string cr2 in
  print_endline cr1_reindented;
  [%expect
    {|
    File "my_file.ml", lines 2-3, characters 2-149:
      CR user1: We want to be able to compute a digest for the message that is stable across
       indentation changes such as across a refactoring.
    |}];
  print_endline cr2_reindented;
  [%expect
    {|
    File "my_file.ml", lines 3-4, characters 4-153:
      CR user1: We want to be able to compute a digest for the message that is stable
       across indentation changes such as across a refactoring.
    |}];
  Expect_test_patdiff.print_patdiff cr1_reindented cr2_reindented;
  [%expect
    {|
    -1,3 +1,3
    -|File "my_file.ml", lines 2-3, characters 2-149:
    +|File "my_file.ml", lines 3-4, characters 4-153:
        CR user1: We want to be able to compute a digest for the message that is stable
         across indentation changes such as across a refactoring.
    |}];
  ()
;;
