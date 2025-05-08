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

module Getters = struct
  type t =
    { path : Vcs.Path_in_repo.t
    ; content : string
    ; kind : Cr_comment.Kind.t
    ; due : Cr_comment.Due.t
    ; work_on : Cr_comment.Due.t
    }
  [@@deriving sexp_of]

  let of_cr cr =
    { path = Cr_comment.path cr
    ; content = Cr_comment.content cr
    ; kind = Cr_comment.kind cr
    ; due = Cr_comment.due cr
    ; work_on = Cr_comment.work_on cr
    }
  ;;
end

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
  let crs = Crs_parser.parse_file ~path ~file_contents |> Cr_comment.sort in
  List.iter crs ~f:(fun t ->
    Ref.set_temporarily Loc.include_sexp_of_locs true ~f:(fun () ->
      let getters = Getters.of_cr t in
      print_s [%sexp { raw = (t : Cr_comment.t); getters : Getters.t }]))
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
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:2:0)))
       (header (Error ("Invalid CR comment" CR)))
       (digest_of_condensed_content 1d7b33fc26ca22c2011aaa97fecc43d8)
       (content CR)))
     (getters (
       (path    my_file.ml)
       (content CR)
       (kind    CR)
       (due     Now)
       (work_on Now))))
    |}];
  ()
;;

let%expect_test "multiple spaces CR" =
  (* Although this should be eventually rejected by a crs linter, having
     multiple spaces leading the the CR is allowed. *)
  test
    {|
(*  $CR user: Blah. *)
|};
  [%expect
    {|
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:2:0)))
       (header (
         Ok (
           (kind (
             (txt CR)
             (loc (
               (start my_file.ml:1:4)
               (stop  my_file.ml:1:6)))))
           (due (
             (txt Now)
             (loc (
               (start my_file.ml:1:4)
               (stop  my_file.ml:1:6)))))
           (reported_by (
             (txt user)
             (loc (
               (start my_file.ml:1:7)
               (stop  my_file.ml:1:11)))))
           (for_ ()))))
       (digest_of_condensed_content a007fb66426c28df02a46d3edf88b6a8)
       (content "CR user: Blah.")))
     (getters (
       (path    my_file.ml)
       (content "CR user: Blah.")
       (kind    CR)
       (due     Now)
       (work_on Now))))
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
    ((raw (
       (path my_file.ml)
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
       (digest_of_condensed_content ad4e5bab97d68f2ee0cd9f6e1a2ec694)
       (content "CR user:")))
     (getters (
       (path    my_file.ml)
       (content "CR user:")
       (kind    CR)
       (due     Now)
       (work_on Now))))
    |}];
  ()
;;

let%expect_test "CR soon, someday" =
  test
    {|
(* $CR-soon user: Some text *)
let () = ()
(* $CR-someday user: Some text *)
let () = ()
(* $CR-soon user1 for user2: Some text *)
let () = ()
(* $CR-someday user1 for user2: Some text *)
let () = ()
(* $XCR-soon user: Some text *)
let () = ()
(* $XCR-someday user: Some text *)
let () = ()
|};
  [%expect
    {|
    ((raw (
       (path my_file.ml)
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
               (start my_file.ml:1:5)
               (stop  my_file.ml:1:10)))))
           (reported_by (
             (txt user)
             (loc (
               (start my_file.ml:1:11)
               (stop  my_file.ml:1:15)))))
           (for_ ()))))
       (digest_of_condensed_content 7324f0b1e8ca40121598816b0e941f22)
       (content "CR-soon user: Some text")))
     (getters (
       (path    my_file.ml)
       (content "CR-soon user: Some text")
       (kind    CR)
       (due     Soon)
       (work_on Soon))))
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:3:0)
         (stop  my_file.ml:3:32)))
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
               (start my_file.ml:3:5)
               (stop  my_file.ml:3:13)))))
           (reported_by (
             (txt user)
             (loc (
               (start my_file.ml:3:14)
               (stop  my_file.ml:3:18)))))
           (for_ ()))))
       (digest_of_condensed_content 0ab8f0769e79ad7515b1cef5b07ffc0d)
       (content "CR-someday user: Some text")))
     (getters (
       (path    my_file.ml)
       (content "CR-someday user: Some text")
       (kind    CR)
       (due     Someday)
       (work_on Someday))))
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:5:0)
         (stop  my_file.ml:5:40)))
       (header (
         Ok (
           (kind (
             (txt CR)
             (loc (
               (start my_file.ml:5:3)
               (stop  my_file.ml:5:5)))))
           (due (
             (txt Soon)
             (loc (
               (start my_file.ml:5:5)
               (stop  my_file.ml:5:10)))))
           (reported_by (
             (txt user1)
             (loc (
               (start my_file.ml:5:11)
               (stop  my_file.ml:5:16)))))
           (for_ ((
             (txt user2)
             (loc (
               (start my_file.ml:5:21)
               (stop  my_file.ml:5:26)))))))))
       (digest_of_condensed_content 25be2533462aad581fdb67607faf5657)
       (content "CR-soon user1 for user2: Some text")))
     (getters (
       (path    my_file.ml)
       (content "CR-soon user1 for user2: Some text")
       (kind    CR)
       (due     Soon)
       (work_on Soon))))
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:7:0)
         (stop  my_file.ml:7:43)))
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
               (start my_file.ml:7:5)
               (stop  my_file.ml:7:13)))))
           (reported_by (
             (txt user1)
             (loc (
               (start my_file.ml:7:14)
               (stop  my_file.ml:7:19)))))
           (for_ ((
             (txt user2)
             (loc (
               (start my_file.ml:7:24)
               (stop  my_file.ml:7:29)))))))))
       (digest_of_condensed_content 7b7561c408ecae947c134d73ffaf5d18)
       (content "CR-someday user1 for user2: Some text")))
     (getters (
       (path    my_file.ml)
       (content "CR-someday user1 for user2: Some text")
       (kind    CR)
       (due     Someday)
       (work_on Someday))))
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:9:0)
         (stop  my_file.ml:9:30)))
       (header (
         Ok (
           (kind (
             (txt XCR)
             (loc (
               (start my_file.ml:9:3)
               (stop  my_file.ml:9:6)))))
           (due (
             (txt Soon)
             (loc (
               (start my_file.ml:9:6)
               (stop  my_file.ml:9:11)))))
           (reported_by (
             (txt user)
             (loc (
               (start my_file.ml:9:12)
               (stop  my_file.ml:9:16)))))
           (for_ ()))))
       (digest_of_condensed_content f96e14832340c9b392986966898d17e0)
       (content "XCR-soon user: Some text")))
     (getters (
       (path    my_file.ml)
       (content "XCR-soon user: Some text")
       (kind    XCR)
       (due     Soon)
       (work_on Now))))
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:11:0)
         (stop  my_file.ml:11:33)))
       (header (
         Ok (
           (kind (
             (txt XCR)
             (loc (
               (start my_file.ml:11:3)
               (stop  my_file.ml:11:6)))))
           (due (
             (txt Someday)
             (loc (
               (start my_file.ml:11:6)
               (stop  my_file.ml:11:14)))))
           (reported_by (
             (txt user)
             (loc (
               (start my_file.ml:11:15)
               (stop  my_file.ml:11:19)))))
           (for_ ()))))
       (digest_of_condensed_content 3bb81d38b56065fc7d5bc222c72cdd81)
       (content "XCR-someday user: Some text")))
     (getters (
       (path    my_file.ml)
       (content "XCR-someday user: Some text")
       (kind    XCR)
       (due     Someday)
       (work_on Now))))
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
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:1:77)))
       (header (
         Error (
           "Invalid CR comment"
           "CR-2026-01-31 user: This CR has a due date, by not correctly specified.")))
       (digest_of_condensed_content 8a2d7636f9f7b2ce8891fe531aac0702)
       (content
        "CR-2026-01-31 user: This CR has a due date, by not correctly specified.")))
     (getters (
       (path my_file.ml)
       (content
        "CR-2026-01-31 user: This CR has a due date, by not correctly specified.")
       (kind    CR)
       (due     Now)
       (work_on Now))))
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:4:0)
         (stop  my_file.ml:4:47)))
       (header (
         Error ("Invalid CR comment" "CR-20260131 user: This is not it either..")))
       (digest_of_condensed_content 6464efa00779bf9b1e422bed9da5834a)
       (content "CR-20260131 user: This is not it either..")))
     (getters (
       (path    my_file.ml)
       (content "CR-20260131 user: This is not it either..")
       (kind    CR)
       (due     Now)
       (work_on Now))))
    ((raw (
       (path my_file.ml)
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
               (start my_file.ml:7:5)
               (stop  my_file.ml:7:12)))))
           (reported_by (
             (txt user)
             (loc (
               (start my_file.ml:7:13)
               (stop  my_file.ml:7:17)))))
           (for_ ()))))
       (digest_of_condensed_content 6531917817eea16f1f90c144e40256a9)
       (content
        "CR-202601 user: You would presumably only include the year and month.")))
     (getters (
       (path my_file.ml)
       (content
        "CR-202601 user: You would presumably only include the year and month.")
       (kind    CR)
       (due     Someday)
       (work_on Someday))))
    |}];
  ()
;;

let%expect_test "CRs on the same line" =
  (* This is an older use case that allowed dates in CRs. Keeping as monitoring
     test for now - whether to keep supporting this functionality is to be
     determined and left as future work. *)
  test
    {|
(* $CR user: A first CR *) let () = () (* $CR user: Followed by another. *)
let () = ()

|};
  [%expect
    {|
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:1:25)))
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
       (digest_of_condensed_content 54765a7c50741e150baed45823334148)
       (content "CR user: A first CR")))
     (getters (
       (path    my_file.ml)
       (content "CR user: A first CR")
       (kind    CR)
       (due     Now)
       (work_on Now))))
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:38)
         (stop  my_file.ml:1:73)))
       (header (
         Ok (
           (kind (
             (txt CR)
             (loc (
               (start my_file.ml:1:41)
               (stop  my_file.ml:1:43)))))
           (due (
             (txt Now)
             (loc (
               (start my_file.ml:1:41)
               (stop  my_file.ml:1:43)))))
           (reported_by (
             (txt user)
             (loc (
               (start my_file.ml:1:44)
               (stop  my_file.ml:1:48)))))
           (for_ ()))))
       (digest_of_condensed_content 2dcc0ec4b6cccc676bec42ea5d3f5cbf)
       (content "CR user: Followed by another.")))
     (getters (
       (path    my_file.ml)
       (content "CR user: Followed by another.")
       (kind    CR)
       (due     Now)
       (work_on Now))))
    |}];
  ()
;;

let%expect_test "digest_ignoring_minor_text_changes" =
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
  [%expect {| 03997213173fb186a59985ae32f89cfd |}];
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
       (digest_of_condensed_content 03997213173fb186a59985ae32f89cfd)
       (content
    -|  "CR user1: We want to be able to compute a digest for the message that is stable across\n     indentation changes such as across a refactoring."))
    +|  "CR user1: We want to be able to compute a digest for the message that is stable\n       across indentation changes such as across a refactoring."))
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

let%expect_test "reindentation" =
  let test file_contents =
    let file_contents =
      file_contents
      |> String.strip
      |> String.substr_replace_all ~pattern:"$CR" ~with_:"CR"
      |> String.substr_replace_all ~pattern:"$XCR" ~with_:"XCR"
      |> Vcs.File_contents.create
    in
    let crs = Crs_parser.parse_file ~path ~file_contents in
    Cr_comment.print_list ~crs
  in
  test "";
  [%expect {||}];
  test
    {|
(* $CR user: A comment that fits on one line. *)

(* $CR user: Let us consider a comment
   that spans multiple lines.

   For the sake of testing, we'll monitor
   comments that are correctly indented.
*)

(* $CR user: As well
as comments that are not.
*)

(* $CR user: At some point we changed the parser to strips the end
   of CR comments.

   So it shouldn't matter how many blank lines are present at the
   end of the comment.



*)

(*   $CR user: What happens when the subsequent lines
   are not lined up with the leading CR keyword?
*)

(* $CR and let us look at invalid comments as well. The exact behavior for
   their intentation is less of a priority since they are invalid in the
   first place. *)

(* $CR-user but still we include
this as part of our tests. *)

(* $CR user: Let's add a couple with trailing spaces    
        
   at the end of some lines.
   
   Hello multiple paragraphs.

      {v
         With possibly some lines whose indentation exceeds the indentation
         of other surrounding lines.
       v}

   user2: Hi! Good tests, good times. *)
|};
  [%expect
    {|
    File "my_file.ml", line 1, characters 0-47:
      CR user: A comment that fits on one line.

    File "my_file.ml", lines 3-8, characters 0-154:
      CR user: Let us consider a comment
      that spans multiple lines.

      For the sake of testing, we'll monitor
      comments that are correctly indented.

    File "my_file.ml", lines 10-12, characters 0-48:
    CR user: As well
    as comments that are not.

    File "my_file.ml", lines 14-22, characters 0-180:
      CR user: At some point we changed the parser to strips the end
      of CR comments.

      So it shouldn't matter how many blank lines are present at the
      end of the comment.

    File "my_file.ml", lines 24-26, characters 0-104:
    CR user: What happens when the subsequent lines
       are not lined up with the leading CR keyword?

    File "my_file.ml", lines 28-30, characters 0-165:
      CR and let us look at invalid comments as well. The exact behavior for
       their intentation is less of a priority since they are invalid in the
       first place.

    File "my_file.ml", lines 32-33, characters 0-61:
    CR-user but still we include
    this as part of our tests.

    File "my_file.ml", lines 35-47, characters 0-302:
      CR user: Let's add a couple with trailing spaces

      at the end of some lines.

      Hello multiple paragraphs.

         {v
            With possibly some lines whose indentation exceeds the indentation
            of other surrounding lines.
          v}

      user2: Hi! Good tests, good times.
    |}];
  ()
;;
