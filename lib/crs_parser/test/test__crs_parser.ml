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

let invariant ~(file_contents : Vcs.File_contents.t) cr =
  let content_start_offset = Cr_comment.content_start_offset cr in
  let comment_prefix = Cr_comment.comment_prefix cr in
  let whole_loc = Cr_comment.whole_loc cr in
  let recompute_prefix =
    let start_pos = Loc.start_offset whole_loc in
    String.sub
      (file_contents :> string)
      ~pos:start_pos
      ~len:(content_start_offset - start_pos)
    |> String.strip
  in
  require_equal [%here] (module String) comment_prefix recompute_prefix;
  ()
;;

module Getters = struct
  type t =
    { path : Vcs.Path_in_repo.t
    ; content : string
    ; status : Cr_comment.Status.t
    ; qualifier : Cr_comment.Qualifier.t option
    ; priority : Cr_comment.Priority.t
    }
  [@@deriving sexp_of]

  let of_cr cr =
    { path = Cr_comment.path cr
    ; content = Cr_comment.content cr
    ; status = Cr_comment.status cr
    ; qualifier =
        (match Cr_comment.header cr with
         | Error _ -> None
         | Ok h -> Some (Cr_comment.Header.qualifier h))
    ; priority = Cr_comment.priority cr
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
  Ref.set_temporarily Loc.include_sexp_of_locs true ~f:(fun () ->
    List.iter crs ~f:(fun t ->
      print_endline "========================";
      invariant ~file_contents t;
      print_endline (Cr_comment.reindented_content t);
      let getters = Getters.of_cr t in
      print_s [%sexp { raw = (t : Cr_comment.t); getters : Getters.t }];
      ()))
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
  (* Here we monitor fragments that may look like CRs but are not. We make use
     of some heurisitic, and opinionated choices, to decide whether to flag
     these constructs as invalid CRs, or simply ignore them. This test is used
     to characterize the behavior around this question. *)
  (* No text. *)
  test
    {|
(* $CR *)
|};
  [%expect
    {|
    ========================
    CR
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:2:0)))
       (content_start_offset 3)
       (header (Error ("Invalid CR comment" CR)))
       (comment_prefix "(*")
       (digest_of_condensed_content 1d7b33fc26ca22c2011aaa97fecc43d8)
       (content CR)))
     (getters (
       (path    my_file.ml)
       (content CR)
       (status  CR)
       (qualifier ())
       (priority Now))))
    |}];
  test
    {|
(* $CR : *)
|};
  [%expect
    {|
    ========================
    CR :
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:2:0)))
       (content_start_offset 3)
       (header (Error ("Invalid CR comment" "CR :")))
       (comment_prefix "(*")
       (digest_of_condensed_content 4ecc072f951465fb458ef1c75ffc6e24)
       (content "CR :")))
     (getters (
       (path    my_file.ml)
       (content "CR :")
       (status  CR)
       (qualifier ())
       (priority Now))))
    |}];
  test
    {|
(* $CR-user *)
|};
  [%expect
    {|
    ========================
    CR-user
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:2:0)))
       (content_start_offset 3)
       (header (Error ("Invalid CR comment" CR-user)))
       (comment_prefix "(*")
       (digest_of_condensed_content b1e92145e4e45e8538a73aece031a01d)
       (content CR-user)))
     (getters (
       (path    my_file.ml)
       (content CR-user)
       (status  CR)
       (qualifier ())
       (priority Now))))
    |}];
  test
    {|
(* $CR-user: *)
|};
  [%expect
    {|
    ========================
    CR-user:
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:2:0)))
       (content_start_offset 3)
       (header (Error ("Invalid CR comment" CR-user:)))
       (comment_prefix "(*")
       (digest_of_condensed_content 17497801764b8cc56107b683d2c30d55)
       (content CR-user:)))
     (getters (
       (path    my_file.ml)
       (content CR-user:)
       (status  CR)
       (qualifier ())
       (priority Now))))
    |}];
  test
    {|
(* $CR user *)
|};
  [%expect
    {|
    ========================
    CR user
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:2:0)))
       (content_start_offset 3)
       (header (Error ("Invalid CR comment" "CR user")))
       (comment_prefix "(*")
       (digest_of_condensed_content d0469bb593e8d5de0103ff72946e8013)
       (content "CR user")))
     (getters (
       (path    my_file.ml)
       (content "CR user")
       (status  CR)
       (qualifier ())
       (priority Now))))
    |}];
  (* With text. *)
  test
    {|
(* $CR : Hello contents. *)
|};
  [%expect
    {|
    ========================
    CR : Hello contents.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:2:0)))
       (content_start_offset 3)
       (header (Error ("Invalid CR comment" "CR : Hello contents.")))
       (comment_prefix "(*")
       (digest_of_condensed_content b4298566357d8b49acb9dde0b4584cfa)
       (content "CR : Hello contents.")))
     (getters (
       (path    my_file.ml)
       (content "CR : Hello contents.")
       (status  CR)
       (qualifier ())
       (priority Now))))
    |}];
  test
    {|
(* $CR-user Hello contents. *)
|};
  [%expect
    {|
    ========================
    CR-user Hello contents.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:2:0)))
       (content_start_offset 3)
       (header (Error ("Invalid CR comment" "CR-user Hello contents.")))
       (comment_prefix "(*")
       (digest_of_condensed_content 65065bf53ad3746b61ee3d1b78e75e4e)
       (content "CR-user Hello contents.")))
     (getters (
       (path    my_file.ml)
       (content "CR-user Hello contents.")
       (status  CR)
       (qualifier ())
       (priority Now))))
    |}];
  test
    {|
(* $CR-user: Hello contents. *)
|};
  [%expect
    {|
    ========================
    CR-user: Hello contents.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:2:0)))
       (content_start_offset 3)
       (header (Error ("Invalid CR comment" "CR-user: Hello contents.")))
       (comment_prefix "(*")
       (digest_of_condensed_content 27f8a76f8a2985b7b0a6275de779cb94)
       (content "CR-user: Hello contents.")))
     (getters (
       (path    my_file.ml)
       (content "CR-user: Hello contents.")
       (status  CR)
       (qualifier ())
       (priority Now))))
    |}];
  test
    {|
(* $CR user
   Hello contents. *)
|};
  [%expect
    {|
    ========================
    CR user
    Hello contents.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:3:0)))
       (content_start_offset 3)
       (header (Error ("Invalid CR comment" "CR user\n   Hello contents.")))
       (comment_prefix "(*")
       (digest_of_condensed_content 5dea3b4b25c1a1d2076715fd5b668168)
       (content "CR user\n   Hello contents.")))
     (getters (
       (path    my_file.ml)
       (content "CR user\n   Hello contents.")
       (status  CR)
       (qualifier ())
       (priority Now))))
    |}];
  ()
;;

let%expect_test "zero spaces CR" =
  (* Although this should be eventually rejected by a crs linter, having
     zero spaces leading to the CR is allowed. *)
  test
    {|
(*$CR user: Hey. *)
|};
  [%expect
    {|
    ========================
    CR user: Hey.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:2:0)))
       (content_start_offset 2)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:1:2)
               (stop  my_file.ml:1:4)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:1:2)
               (stop  my_file.ml:1:4)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:1:5)
               (stop  my_file.ml:1:9)))))
           (recipient ()))))
       (comment_prefix "(*")
       (digest_of_condensed_content bcdc93702bfd70659516c872b7186f26)
       (content "CR user: Hey.")))
     (getters (
       (path    my_file.ml)
       (content "CR user: Hey.")
       (status  CR)
       (qualifier (None))
       (priority Now))))
    |}];
  test
    {|
#$CR user: Hey.
|};
  [%expect
    {|
    ========================
    CR user: Hey.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:2:0)))
       (content_start_offset 1)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:1:1)
               (stop  my_file.ml:1:3)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:1:1)
               (stop  my_file.ml:1:3)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:1:4)
               (stop  my_file.ml:1:8)))))
           (recipient ()))))
       (comment_prefix #)
       (digest_of_condensed_content bcdc93702bfd70659516c872b7186f26)
       (content "CR user: Hey.")))
     (getters (
       (path    my_file.ml)
       (content "CR user: Hey.")
       (status  CR)
       (qualifier (None))
       (priority Now))))
    |}];
  ()
;;

let%expect_test "multiple spaces CR" =
  (* Although this should be eventually rejected by a crs linter, having
     multiple spaces leading to the CR is allowed. *)
  test
    {|
(*  $CR user: Blah. *)
|};
  [%expect
    {|
    ========================
    CR user: Blah.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:2:0)))
       (content_start_offset 4)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:1:4)
               (stop  my_file.ml:1:6)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:1:4)
               (stop  my_file.ml:1:6)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:1:7)
               (stop  my_file.ml:1:11)))))
           (recipient ()))))
       (comment_prefix "(*")
       (digest_of_condensed_content a007fb66426c28df02a46d3edf88b6a8)
       (content "CR user: Blah.")))
     (getters (
       (path    my_file.ml)
       (content "CR user: Blah.")
       (status  CR)
       (qualifier (None))
       (priority Now))))
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
    ========================
    CR user:
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:2:0)))
       (content_start_offset 3)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:1:3)
               (stop  my_file.ml:1:5)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:1:3)
               (stop  my_file.ml:1:5)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:1:6)
               (stop  my_file.ml:1:10)))))
           (recipient ()))))
       (comment_prefix "(*")
       (digest_of_condensed_content ad4e5bab97d68f2ee0cd9f6e1a2ec694)
       (content "CR user:")))
     (getters (
       (path    my_file.ml)
       (content "CR user:")
       (status  CR)
       (qualifier (None))
       (priority Now))))
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
    ========================
    CR-soon user: Some text
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:1:29)))
       (content_start_offset 3)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:1:3)
               (stop  my_file.ml:1:5)))))
           (qualifier (
             (txt Soon)
             (loc (
               (start my_file.ml:1:6)
               (stop  my_file.ml:1:10)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:1:11)
               (stop  my_file.ml:1:15)))))
           (recipient ()))))
       (comment_prefix "(*")
       (digest_of_condensed_content 7324f0b1e8ca40121598816b0e941f22)
       (content "CR-soon user: Some text")))
     (getters (
       (path    my_file.ml)
       (content "CR-soon user: Some text")
       (status  CR)
       (qualifier (Soon))
       (priority Soon))))
    ========================
    CR-someday user: Some text
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:3:0)
         (stop  my_file.ml:3:32)))
       (content_start_offset 45)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:3:3)
               (stop  my_file.ml:3:5)))))
           (qualifier (
             (txt Someday)
             (loc (
               (start my_file.ml:3:6)
               (stop  my_file.ml:3:13)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:3:14)
               (stop  my_file.ml:3:18)))))
           (recipient ()))))
       (comment_prefix "(*")
       (digest_of_condensed_content 0ab8f0769e79ad7515b1cef5b07ffc0d)
       (content "CR-someday user: Some text")))
     (getters (
       (path    my_file.ml)
       (content "CR-someday user: Some text")
       (status  CR)
       (qualifier (Someday))
       (priority Someday))))
    ========================
    CR-soon user1 for user2: Some text
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:5:0)
         (stop  my_file.ml:5:40)))
       (content_start_offset 90)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:5:3)
               (stop  my_file.ml:5:5)))))
           (qualifier (
             (txt Soon)
             (loc (
               (start my_file.ml:5:6)
               (stop  my_file.ml:5:10)))))
           (reporter (
             (txt user1)
             (loc (
               (start my_file.ml:5:11)
               (stop  my_file.ml:5:16)))))
           (recipient ((
             (txt user2)
             (loc (
               (start my_file.ml:5:21)
               (stop  my_file.ml:5:26)))))))))
       (comment_prefix "(*")
       (digest_of_condensed_content 25be2533462aad581fdb67607faf5657)
       (content "CR-soon user1 for user2: Some text")))
     (getters (
       (path    my_file.ml)
       (content "CR-soon user1 for user2: Some text")
       (status  CR)
       (qualifier (Soon))
       (priority Soon))))
    ========================
    CR-someday user1 for user2: Some text
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:7:0)
         (stop  my_file.ml:7:43)))
       (content_start_offset 143)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:7:3)
               (stop  my_file.ml:7:5)))))
           (qualifier (
             (txt Someday)
             (loc (
               (start my_file.ml:7:6)
               (stop  my_file.ml:7:13)))))
           (reporter (
             (txt user1)
             (loc (
               (start my_file.ml:7:14)
               (stop  my_file.ml:7:19)))))
           (recipient ((
             (txt user2)
             (loc (
               (start my_file.ml:7:24)
               (stop  my_file.ml:7:29)))))))))
       (comment_prefix "(*")
       (digest_of_condensed_content 7b7561c408ecae947c134d73ffaf5d18)
       (content "CR-someday user1 for user2: Some text")))
     (getters (
       (path    my_file.ml)
       (content "CR-someday user1 for user2: Some text")
       (status  CR)
       (qualifier (Someday))
       (priority Someday))))
    ========================
    XCR-soon user: Some text
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:9:0)
         (stop  my_file.ml:9:30)))
       (content_start_offset 199)
       (header (
         Ok (
           (status (
             (txt XCR)
             (loc (
               (start my_file.ml:9:3)
               (stop  my_file.ml:9:6)))))
           (qualifier (
             (txt Soon)
             (loc (
               (start my_file.ml:9:7)
               (stop  my_file.ml:9:11)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:9:12)
               (stop  my_file.ml:9:16)))))
           (recipient ()))))
       (comment_prefix "(*")
       (digest_of_condensed_content f96e14832340c9b392986966898d17e0)
       (content "XCR-soon user: Some text")))
     (getters (
       (path    my_file.ml)
       (content "XCR-soon user: Some text")
       (status  XCR)
       (qualifier (Soon))
       (priority Now))))
    ========================
    XCR-someday user: Some text
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:11:0)
         (stop  my_file.ml:11:33)))
       (content_start_offset 242)
       (header (
         Ok (
           (status (
             (txt XCR)
             (loc (
               (start my_file.ml:11:3)
               (stop  my_file.ml:11:6)))))
           (qualifier (
             (txt Someday)
             (loc (
               (start my_file.ml:11:7)
               (stop  my_file.ml:11:14)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:11:15)
               (stop  my_file.ml:11:19)))))
           (recipient ()))))
       (comment_prefix "(*")
       (digest_of_condensed_content 3bb81d38b56065fc7d5bc222c72cdd81)
       (content "XCR-someday user: Some text")))
     (getters (
       (path    my_file.ml)
       (content "XCR-someday user: Some text")
       (status  XCR)
       (qualifier (Someday))
       (priority Now))))
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
    ========================
    CR-2026-01-31 user: This CR has a due date, by not correctly specified.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:1:77)))
       (content_start_offset 3)
       (header (
         Error (
           "Invalid CR comment"
           "CR-2026-01-31 user: This CR has a due date, by not correctly specified.")))
       (comment_prefix "(*")
       (digest_of_condensed_content 8a2d7636f9f7b2ce8891fe531aac0702)
       (content
        "CR-2026-01-31 user: This CR has a due date, by not correctly specified.")))
     (getters (
       (path my_file.ml)
       (content
        "CR-2026-01-31 user: This CR has a due date, by not correctly specified.")
       (status CR)
       (qualifier ())
       (priority Now))))
    ========================
    CR-20260131 user: This is not it either..
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:4:0)
         (stop  my_file.ml:4:47)))
       (content_start_offset 94)
       (header (
         Error ("Invalid CR comment" "CR-20260131 user: This is not it either..")))
       (comment_prefix "(*")
       (digest_of_condensed_content 6464efa00779bf9b1e422bed9da5834a)
       (content "CR-20260131 user: This is not it either..")))
     (getters (
       (path    my_file.ml)
       (content "CR-20260131 user: This is not it either..")
       (status  CR)
       (qualifier ())
       (priority Now))))
    ========================
    CR-202601 user: You would presumably only include the year and month.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:7:0)
         (stop  my_file.ml:7:75)))
       (content_start_offset 155)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:7:3)
               (stop  my_file.ml:7:5)))))
           (qualifier (
             (txt Someday)
             (loc (
               (start my_file.ml:7:6)
               (stop  my_file.ml:7:12)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:7:13)
               (stop  my_file.ml:7:17)))))
           (recipient ()))))
       (comment_prefix "(*")
       (digest_of_condensed_content 6531917817eea16f1f90c144e40256a9)
       (content
        "CR-202601 user: You would presumably only include the year and month.")))
     (getters (
       (path my_file.ml)
       (content
        "CR-202601 user: You would presumably only include the year and month.")
       (status CR)
       (qualifier (Someday))
       (priority Someday))))
    |}];
  ()
;;

let%expect_test "CRs on the same line" =
  test
    {|
(* $CR user: A first CR *) let () = () (* $CR user: Followed by another. *)
let () = ()

|};
  [%expect
    {|
    ========================
    CR user: A first CR
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:1:25)))
       (content_start_offset 3)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:1:3)
               (stop  my_file.ml:1:5)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:1:3)
               (stop  my_file.ml:1:5)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:1:6)
               (stop  my_file.ml:1:10)))))
           (recipient ()))))
       (comment_prefix "(*")
       (digest_of_condensed_content 54765a7c50741e150baed45823334148)
       (content "CR user: A first CR")))
     (getters (
       (path    my_file.ml)
       (content "CR user: A first CR")
       (status  CR)
       (qualifier (None))
       (priority Now))))
    ========================
    CR user: Followed by another.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:38)
         (stop  my_file.ml:1:73)))
       (content_start_offset 41)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:1:41)
               (stop  my_file.ml:1:43)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:1:41)
               (stop  my_file.ml:1:43)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:1:44)
               (stop  my_file.ml:1:48)))))
           (recipient ()))))
       (comment_prefix "(*")
       (digest_of_condensed_content 2dcc0ec4b6cccc676bec42ea5d3f5cbf)
       (content "CR user: Followed by another.")))
     (getters (
       (path    my_file.ml)
       (content "CR user: Followed by another.")
       (status  CR)
       (qualifier (None))
       (priority Now))))
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
    -1,13 +1,13
      ((path                 my_file.ml)
       (whole_loc            _)
    -| (content_start_offset 16)
    +| (content_start_offset 38)
       (header (
         Ok (
           (status    CR)
           (qualifier None)
           (reporter  user1)
           (recipient ()))))
       (comment_prefix "(*")
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
  let parse_file ~file_contents =
    let file_contents =
      file_contents
      |> String.strip
      |> String.substr_replace_all ~pattern:"$CR" ~with_:"CR"
      |> String.substr_replace_all ~pattern:"$XCR" ~with_:"XCR"
      |> Vcs.File_contents.create
    in
    Crs_parser.parse_file ~path ~file_contents
  in
  let test file_contents =
    let crs = parse_file ~file_contents in
    Cr_comment.print_list crs
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
   their indentation is less of a priority since they are invalid in the
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

(*$CR user: A cr that aligns its lines with CR that has no spaces.
  Hey *)

#$CR user: A cr that aligns its lines with CR that has no spaces.
#
#Hey

# $CR user: A cr that has a line that has no spaces.
#
#Hey
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
      their indentation is less of a priority since they are invalid in the
      first place.

    File "my_file.ml", lines 32-33, characters 0-61:
      CR-user but still we include
      this as part of our tests.

    File "my_file.ml", lines 35-46, characters 0-302:
      CR user: Let's add a couple with trailing spaces

      at the end of some lines.

      Hello multiple paragraphs.

         {v
            With possibly some lines whose indentation exceeds the indentation
            of other surrounding lines.
          v}

      user2: Hi! Good tests, good times.

    File "my_file.ml", lines 48-49, characters 0-74:
      CR user: A cr that aligns its lines with CR that has no spaces.
      Hey

    File "my_file.ml", lines 51-53, characters 0-71:
      CR user: A cr that aligns its lines with CR that has no spaces.

      Hey

    File "my_file.ml", lines 55-58, characters 0-58:
      CR user: A cr that has a line that has no spaces.

      Hey
    |}];
  (* There was an issue with multiple lines comments when each line starts with
     the comment delimiter. The delimiter used to be captured as being part of
     the contents. This was fixed. Keeping as monitoring tests. *)
  test
    {|
// $CR user: This is a multiple lines CR in the c-style
// We should try and remove the delimiter prefix from subsequent lines.

;; $CR user: Note that this is not limited to c-style comments.
;; Basically any language where delimiters start the line has this issue.

;; $CR user: This may require further considerations
; when the syntax allows different number
;; of delimiters on each line.

; $CR user: What we do is that we base it on the number of delimiters
;; of the first line.
; So, lines that have more will keep their prefix.

-- $CR user: Hello to
-- multi-line comments in sql-syntax too!

(This is a sexp
  (with potentially some indentation
    ;; $CR user: In which case the comment may be indented as well
    ;; as being on multiple lines. We'd like to cover this too.
 ))
|};
  [%expect
    {|
    File "my_file.ml", lines 1-2, characters 0-126:
      CR user: This is a multiple lines CR in the c-style
      We should try and remove the delimiter prefix from subsequent lines.

    File "my_file.ml", lines 4-5, characters 0-136:
      CR user: Note that this is not limited to c-style comments.
      Basically any language where delimiters start the line has this issue.

    File "my_file.ml", lines 7-9, characters 0-124:
      CR user: This may require further considerations
      ; when the syntax allows different number
      of delimiters on each line.

    File "my_file.ml", lines 11-13, characters 0-141:
      CR user: What we do is that we base it on the number of delimiters
      ; of the first line.
      So, lines that have more will keep their prefix.

    File "my_file.ml", lines 15-16, characters 0-62:
      CR user: Hello to
      multi-line comments in sql-syntax too!

    File "my_file.ml", lines 20-21, characters 4-129:
      CR user: In which case the comment may be indented as well
      as being on multiple lines. We'd like to cover this too.
    |}];
  let with_margin file_contents =
    let crs = parse_file ~file_contents in
    List.iter crs ~f:(fun cr ->
      print_endline (Cr_comment.reindented_content cr ~new_line_prefix:"| "))
  in
  with_margin
    {|
(* $XCR user: We test that we produce correctly rstripped lines when using margins.

   And the cr contains empty lines. *)
|};
  [%expect
    {|
    | XCR user: We test that we produce correctly rstripped lines when using margins.
    |
    | And the cr contains empty lines.
    |}];
  with_margin
    {|
;; $XCR user: We test that we produce correctly rstripped lines when using margins.
;;
;; And the cr contains empty lines. *)
|};
  [%expect
    {|
    | XCR user: We test that we produce correctly rstripped lines when using margins.
    |
    | And the cr contains empty lines. *)
    |}];
  ()
;;

(* Covering for other comment syntaxes supported. *)

let%expect_test "c-style" =
  test
    {|
/* $CR user: This is a comment. */

/* $XCR user: And it can
span multiple lines too.
*/
|};
  [%expect
    {|
    ========================
    CR user: This is a comment.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:1:33)))
       (content_start_offset 3)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:1:3)
               (stop  my_file.ml:1:5)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:1:3)
               (stop  my_file.ml:1:5)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:1:6)
               (stop  my_file.ml:1:10)))))
           (recipient ()))))
       (comment_prefix /*)
       (digest_of_condensed_content 163bbcea849da7f4b4bc94be0c158f3b)
       (content "CR user: This is a comment.")))
     (getters (
       (path    my_file.ml)
       (content "CR user: This is a comment.")
       (status  CR)
       (qualifier (None))
       (priority Now))))
    ========================
    XCR user: And it can
    span multiple lines too.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:3:0)
         (stop  my_file.ml:6:0)))
       (content_start_offset 38)
       (header (
         Ok (
           (status (
             (txt XCR)
             (loc (
               (start my_file.ml:3:3)
               (stop  my_file.ml:3:6)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:3:3)
               (stop  my_file.ml:3:6)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:3:7)
               (stop  my_file.ml:3:11)))))
           (recipient ()))))
       (comment_prefix /*)
       (digest_of_condensed_content b0cd03d9b3fa2989b1733e82d73c65cf)
       (content "XCR user: And it can\nspan multiple lines too.")))
     (getters (
       (path my_file.ml)
       (content "XCR user: And it can\nspan multiple lines too.")
       (status XCR)
       (qualifier (None))
       (priority Now))))
    |}];
  test
    {|
// $CR user: This is a single line comment.

// $XCR user: This syntax can be used to write
// comments that span multiple lines too.
|};
  [%expect
    {|
    ========================
    CR user: This is a single line comment.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:1:42)))
       (content_start_offset 3)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:1:3)
               (stop  my_file.ml:1:5)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:1:3)
               (stop  my_file.ml:1:5)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:1:6)
               (stop  my_file.ml:1:10)))))
           (recipient ()))))
       (comment_prefix //)
       (digest_of_condensed_content cb6422de18b3ec708df5f2176d6d0255)
       (content "CR user: This is a single line comment.")))
     (getters (
       (path    my_file.ml)
       (content "CR user: This is a single line comment.")
       (status  CR)
       (qualifier (None))
       (priority Now))))
    ========================
    XCR user: This syntax can be used to write
    comments that span multiple lines too.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:3:0)
         (stop  my_file.ml:5:0)))
       (content_start_offset 47)
       (header (
         Ok (
           (status (
             (txt XCR)
             (loc (
               (start my_file.ml:3:3)
               (stop  my_file.ml:3:6)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:3:3)
               (stop  my_file.ml:3:6)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:3:7)
               (stop  my_file.ml:3:11)))))
           (recipient ()))))
       (comment_prefix //)
       (digest_of_condensed_content 779812c3126e3a16333ad9264b741f75)
       (content
        "XCR user: This syntax can be used to write\n// comments that span multiple lines too.")))
     (getters (
       (path my_file.ml)
       (content
        "XCR user: This syntax can be used to write\n// comments that span multiple lines too.")
       (status XCR)
       (qualifier (None))
       (priority Now))))
    |}];
  test
    {|
/* $CR user: This is a c-style comment but with no comment ending.
|};
  [%expect {||}];
  ()
;;

let%expect_test "single-hash-style" =
  test
    {|
# $CR user: This is a comment.

# $XCR user: And it can
# span multiple lines too.

Hello text # $CR user: Comment may be left next to a non-empty line.

  # $CR user: Let's cover the case
  #
  # Where there are empty lines that are part of the comment.
  # This happens when the CR has multiple paragraphs.
|};
  [%expect
    {|
    ========================
    CR user: This is a comment.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:1:29)))
       (content_start_offset 2)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:1:2)
               (stop  my_file.ml:1:4)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:1:2)
               (stop  my_file.ml:1:4)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:1:5)
               (stop  my_file.ml:1:9)))))
           (recipient ()))))
       (comment_prefix #)
       (digest_of_condensed_content 163bbcea849da7f4b4bc94be0c158f3b)
       (content "CR user: This is a comment.")))
     (getters (
       (path    my_file.ml)
       (content "CR user: This is a comment.")
       (status  CR)
       (qualifier (None))
       (priority Now))))
    ========================
    XCR user: And it can
    span multiple lines too.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:3:0)
         (stop  my_file.ml:4:26)))
       (content_start_offset 33)
       (header (
         Ok (
           (status (
             (txt XCR)
             (loc (
               (start my_file.ml:3:2)
               (stop  my_file.ml:3:5)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:3:2)
               (stop  my_file.ml:3:5)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:3:6)
               (stop  my_file.ml:3:10)))))
           (recipient ()))))
       (comment_prefix #)
       (digest_of_condensed_content a9cae35010ee7de740f2152952982a10)
       (content "XCR user: And it can\n# span multiple lines too.")))
     (getters (
       (path my_file.ml)
       (content "XCR user: And it can\n# span multiple lines too.")
       (status XCR)
       (qualifier (None))
       (priority Now))))
    ========================
    CR user: Comment may be left next to a non-empty line.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:6:11)
         (stop  my_file.ml:6:67)))
       (content_start_offset 95)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:6:13)
               (stop  my_file.ml:6:15)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:6:13)
               (stop  my_file.ml:6:15)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:6:16)
               (stop  my_file.ml:6:20)))))
           (recipient ()))))
       (comment_prefix #)
       (digest_of_condensed_content 578d4a5fa32ea8eb96dcfadd364f5970)
       (content "CR user: Comment may be left next to a non-empty line.")))
     (getters (
       (path my_file.ml)
       (content "CR user: Comment may be left next to a non-empty line.")
       (status CR)
       (qualifier (None))
       (priority Now))))
    ========================
    CR user: Let's cover the case

    Where there are empty lines that are part of the comment.
    This happens when the CR has multiple paragraphs.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:8:2)
         (stop  my_file.ml:12:0)))
       (content_start_offset 155)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:8:4)
               (stop  my_file.ml:8:6)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:8:4)
               (stop  my_file.ml:8:6)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:8:7)
               (stop  my_file.ml:8:11)))))
           (recipient ()))))
       (comment_prefix #)
       (digest_of_condensed_content 5112e33a61329692231b5bf143b141a5)
       (content
        "CR user: Let's cover the case\n  #\n  # Where there are empty lines that are part of the comment.\n  # This happens when the CR has multiple paragraphs.")))
     (getters (
       (path my_file.ml)
       (content
        "CR user: Let's cover the case\n  #\n  # Where there are empty lines that are part of the comment.\n  # This happens when the CR has multiple paragraphs.")
       (status CR)
       (qualifier (None))
       (priority Now))))
    |}];
  ()
;;

let%expect_test "double-hash-style" =
  test
    {|
## $CR user: This is a comment.

## $XCR user: And it can
## span multiple lines too.

Hello text ## $CR user: Comment may be left next to a non-empty line.

  ## $CR user: Let's cover the case
  ##
  ## Where there are empty lines that are part of the comment.
  ## This happens when the CR has multiple paragraphs.
|};
  [%expect
    {|
    ========================
    CR user: This is a comment.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:1:30)))
       (content_start_offset 3)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:1:3)
               (stop  my_file.ml:1:5)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:1:3)
               (stop  my_file.ml:1:5)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:1:6)
               (stop  my_file.ml:1:10)))))
           (recipient ()))))
       (comment_prefix ##)
       (digest_of_condensed_content 163bbcea849da7f4b4bc94be0c158f3b)
       (content "CR user: This is a comment.")))
     (getters (
       (path    my_file.ml)
       (content "CR user: This is a comment.")
       (status  CR)
       (qualifier (None))
       (priority Now))))
    ========================
    XCR user: And it can
    span multiple lines too.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:3:0)
         (stop  my_file.ml:4:27)))
       (content_start_offset 35)
       (header (
         Ok (
           (status (
             (txt XCR)
             (loc (
               (start my_file.ml:3:3)
               (stop  my_file.ml:3:6)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:3:3)
               (stop  my_file.ml:3:6)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:3:7)
               (stop  my_file.ml:3:11)))))
           (recipient ()))))
       (comment_prefix ##)
       (digest_of_condensed_content 8ca974bb302fc0e99f44c0a33c33c787)
       (content "XCR user: And it can\n## span multiple lines too.")))
     (getters (
       (path my_file.ml)
       (content "XCR user: And it can\n## span multiple lines too.")
       (status XCR)
       (qualifier (None))
       (priority Now))))
    ========================
    CR user: Comment may be left next to a non-empty line.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:6:11)
         (stop  my_file.ml:6:68)))
       (content_start_offset 99)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:6:14)
               (stop  my_file.ml:6:16)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:6:14)
               (stop  my_file.ml:6:16)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:6:17)
               (stop  my_file.ml:6:21)))))
           (recipient ()))))
       (comment_prefix ##)
       (digest_of_condensed_content 578d4a5fa32ea8eb96dcfadd364f5970)
       (content "CR user: Comment may be left next to a non-empty line.")))
     (getters (
       (path my_file.ml)
       (content "CR user: Comment may be left next to a non-empty line.")
       (status CR)
       (qualifier (None))
       (priority Now))))
    ========================
    CR user: Let's cover the case

    Where there are empty lines that are part of the comment.
    This happens when the CR has multiple paragraphs.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:8:2)
         (stop  my_file.ml:12:0)))
       (content_start_offset 160)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:8:5)
               (stop  my_file.ml:8:7)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:8:5)
               (stop  my_file.ml:8:7)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:8:8)
               (stop  my_file.ml:8:12)))))
           (recipient ()))))
       (comment_prefix ##)
       (digest_of_condensed_content c996cd4ecdb0a43a61975f81638e5107)
       (content
        "CR user: Let's cover the case\n  ##\n  ## Where there are empty lines that are part of the comment.\n  ## This happens when the CR has multiple paragraphs.")))
     (getters (
       (path my_file.ml)
       (content
        "CR user: Let's cover the case\n  ##\n  ## Where there are empty lines that are part of the comment.\n  ## This happens when the CR has multiple paragraphs.")
       (status CR)
       (qualifier (None))
       (priority Now))))
    |}];
  test
    {|
Hello ## $CR user: By the way, multiple hash is supported. The location for the entire
      ## comment starts at the left-most hash character.
|};
  [%expect
    {|
    ========================
    CR user: By the way, multiple hash is supported. The location for the entire
    comment starts at the left-most hash character.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:6)
         (stop  my_file.ml:3:0)))
       (content_start_offset 9)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:1:9)
               (stop  my_file.ml:1:11)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:1:9)
               (stop  my_file.ml:1:11)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:1:12)
               (stop  my_file.ml:1:16)))))
           (recipient ()))))
       (comment_prefix ##)
       (digest_of_condensed_content 7eb8677422f6c5a1a173dd94a6c2ff8d)
       (content
        "CR user: By the way, multiple hash is supported. The location for the entire\n      ## comment starts at the left-most hash character.")))
     (getters (
       (path my_file.ml)
       (content
        "CR user: By the way, multiple hash is supported. The location for the entire\n      ## comment starts at the left-most hash character.")
       (status CR)
       (qualifier (None))
       (priority Now))))
    |}];
  ()
;;

let%expect_test "single-dash-style" =
  (* This is currently not part of a supported syntax for comments. *)
  test
    {|
- $CR user: This is a comment.

- $XCR user: And it can
- span multiple lines too.

Hello text - $CR user: Comment may be left next to a non-empty line.
|};
  [%expect {||}];
  ()
;;

let%expect_test "double-dash-style" =
  test
    {|
-- $CR user: This is a comment.

-- $XCR user: And it can
-- span multiple lines too.

Hello text -- $CR user: Comment may be left next to a non-empty line.
|};
  [%expect
    {|
    ========================
    CR user: This is a comment.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:1:30)))
       (content_start_offset 3)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:1:3)
               (stop  my_file.ml:1:5)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:1:3)
               (stop  my_file.ml:1:5)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:1:6)
               (stop  my_file.ml:1:10)))))
           (recipient ()))))
       (comment_prefix --)
       (digest_of_condensed_content 163bbcea849da7f4b4bc94be0c158f3b)
       (content "CR user: This is a comment.")))
     (getters (
       (path    my_file.ml)
       (content "CR user: This is a comment.")
       (status  CR)
       (qualifier (None))
       (priority Now))))
    ========================
    XCR user: And it can
    span multiple lines too.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:3:0)
         (stop  my_file.ml:4:27)))
       (content_start_offset 35)
       (header (
         Ok (
           (status (
             (txt XCR)
             (loc (
               (start my_file.ml:3:3)
               (stop  my_file.ml:3:6)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:3:3)
               (stop  my_file.ml:3:6)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:3:7)
               (stop  my_file.ml:3:11)))))
           (recipient ()))))
       (comment_prefix --)
       (digest_of_condensed_content 0c475f77a37f48a47f734f053571e2c5)
       (content "XCR user: And it can\n-- span multiple lines too.")))
     (getters (
       (path my_file.ml)
       (content "XCR user: And it can\n-- span multiple lines too.")
       (status XCR)
       (qualifier (None))
       (priority Now))))
    ========================
    CR user: Comment may be left next to a non-empty line.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:6:11)
         (stop  my_file.ml:7:0)))
       (content_start_offset 99)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:6:14)
               (stop  my_file.ml:6:16)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:6:14)
               (stop  my_file.ml:6:16)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:6:17)
               (stop  my_file.ml:6:21)))))
           (recipient ()))))
       (comment_prefix --)
       (digest_of_condensed_content 578d4a5fa32ea8eb96dcfadd364f5970)
       (content "CR user: Comment may be left next to a non-empty line.")))
     (getters (
       (path my_file.ml)
       (content "CR user: Comment may be left next to a non-empty line.")
       (status CR)
       (qualifier (None))
       (priority Now))))
    |}];
  ()
;;

let%expect_test "single-semi-style" =
  test
    {|
; $CR user: This is a comment.

; $XCR user: And it can
; span multiple lines too.

(This is a sexp     ; $CR user: Comment may be placed after a non-empty line.
  spanning multiple
  lines) ; $CR user: Comment may span multiple
         ; lines too.

  ; $CR user: Let's cover the case
  ;
  ; Where there are empty lines that are part of the comment.
  ; This happens when the CR has multiple paragraphs.
|};
  [%expect
    {|
    ========================
    CR user: This is a comment.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:1:29)))
       (content_start_offset 2)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:1:2)
               (stop  my_file.ml:1:4)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:1:2)
               (stop  my_file.ml:1:4)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:1:5)
               (stop  my_file.ml:1:9)))))
           (recipient ()))))
       (comment_prefix ";")
       (digest_of_condensed_content 163bbcea849da7f4b4bc94be0c158f3b)
       (content "CR user: This is a comment.")))
     (getters (
       (path    my_file.ml)
       (content "CR user: This is a comment.")
       (status  CR)
       (qualifier (None))
       (priority Now))))
    ========================
    XCR user: And it can
    span multiple lines too.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:3:0)
         (stop  my_file.ml:4:26)))
       (content_start_offset 33)
       (header (
         Ok (
           (status (
             (txt XCR)
             (loc (
               (start my_file.ml:3:2)
               (stop  my_file.ml:3:5)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:3:2)
               (stop  my_file.ml:3:5)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:3:6)
               (stop  my_file.ml:3:10)))))
           (recipient ()))))
       (comment_prefix ";")
       (digest_of_condensed_content b1b46945ef550294693fab3aff025b3c)
       (content "XCR user: And it can\n; span multiple lines too.")))
     (getters (
       (path my_file.ml)
       (content "XCR user: And it can\n; span multiple lines too.")
       (status XCR)
       (qualifier (None))
       (priority Now))))
    ========================
    CR user: Comment may be placed after a non-empty line.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:6:20)
         (stop  my_file.ml:6:76)))
       (content_start_offset 104)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:6:22)
               (stop  my_file.ml:6:24)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:6:22)
               (stop  my_file.ml:6:24)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:6:25)
               (stop  my_file.ml:6:29)))))
           (recipient ()))))
       (comment_prefix ";")
       (digest_of_condensed_content 66bfce0646f71201f4c5d0a1bea8b4e7)
       (content "CR user: Comment may be placed after a non-empty line.")))
     (getters (
       (path my_file.ml)
       (content "CR user: Comment may be placed after a non-empty line.")
       (status CR)
       (qualifier (None))
       (priority Now))))
    ========================
    CR user: Comment may span multiple
    lines too.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:8:9)
         (stop  my_file.ml:9:21)))
       (content_start_offset 190)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:8:11)
               (stop  my_file.ml:8:13)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:8:11)
               (stop  my_file.ml:8:13)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:8:14)
               (stop  my_file.ml:8:18)))))
           (recipient ()))))
       (comment_prefix ";")
       (digest_of_condensed_content bd754cb26662424382ff7cd77316ce37)
       (content "CR user: Comment may span multiple\n         ; lines too.")))
     (getters (
       (path my_file.ml)
       (content "CR user: Comment may span multiple\n         ; lines too.")
       (status CR)
       (qualifier (None))
       (priority Now))))
    ========================
    CR user: Let's cover the case

    Where there are empty lines that are part of the comment.
    This happens when the CR has multiple paragraphs.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:11:2)
         (stop  my_file.ml:15:0)))
       (content_start_offset 252)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:11:4)
               (stop  my_file.ml:11:6)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:11:4)
               (stop  my_file.ml:11:6)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:11:7)
               (stop  my_file.ml:11:11)))))
           (recipient ()))))
       (comment_prefix ";")
       (digest_of_condensed_content eef985611075b182b3f77ab176ad2bab)
       (content
        "CR user: Let's cover the case\n  ;\n  ; Where there are empty lines that are part of the comment.\n  ; This happens when the CR has multiple paragraphs.")))
     (getters (
       (path my_file.ml)
       (content
        "CR user: Let's cover the case\n  ;\n  ; Where there are empty lines that are part of the comment.\n  ; This happens when the CR has multiple paragraphs.")
       (status CR)
       (qualifier (None))
       (priority Now))))
    |}];
  ()
;;

let%expect_test "double-semi-style" =
  test
    {|
;; $CR user: This is a comment.

;; $XCR user: And it can
;; span multiple lines too.

(This is a sexp     ;; $CR user: Comment may be placed after a non-empty line.
  spanning multiple
  lines) ;; $CR user: Comment may span multiple
         ;; lines too.

  ;; $CR user: Let's cover the case
  ;;
  ;; Where there are empty lines that are part of the comment.
  ;; This happens when the CR has multiple paragraphs.
|};
  [%expect
    {|
    ========================
    CR user: This is a comment.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:1:30)))
       (content_start_offset 3)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:1:3)
               (stop  my_file.ml:1:5)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:1:3)
               (stop  my_file.ml:1:5)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:1:6)
               (stop  my_file.ml:1:10)))))
           (recipient ()))))
       (comment_prefix ";;")
       (digest_of_condensed_content 163bbcea849da7f4b4bc94be0c158f3b)
       (content "CR user: This is a comment.")))
     (getters (
       (path    my_file.ml)
       (content "CR user: This is a comment.")
       (status  CR)
       (qualifier (None))
       (priority Now))))
    ========================
    XCR user: And it can
    span multiple lines too.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:3:0)
         (stop  my_file.ml:4:27)))
       (content_start_offset 35)
       (header (
         Ok (
           (status (
             (txt XCR)
             (loc (
               (start my_file.ml:3:3)
               (stop  my_file.ml:3:6)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:3:3)
               (stop  my_file.ml:3:6)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:3:7)
               (stop  my_file.ml:3:11)))))
           (recipient ()))))
       (comment_prefix ";;")
       (digest_of_condensed_content c59442a767269767df392a109a8e074b)
       (content "XCR user: And it can\n;; span multiple lines too.")))
     (getters (
       (path my_file.ml)
       (content "XCR user: And it can\n;; span multiple lines too.")
       (status XCR)
       (qualifier (None))
       (priority Now))))
    ========================
    CR user: Comment may be placed after a non-empty line.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:6:20)
         (stop  my_file.ml:6:77)))
       (content_start_offset 108)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:6:23)
               (stop  my_file.ml:6:25)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:6:23)
               (stop  my_file.ml:6:25)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:6:26)
               (stop  my_file.ml:6:30)))))
           (recipient ()))))
       (comment_prefix ";;")
       (digest_of_condensed_content 66bfce0646f71201f4c5d0a1bea8b4e7)
       (content "CR user: Comment may be placed after a non-empty line.")))
     (getters (
       (path my_file.ml)
       (content "CR user: Comment may be placed after a non-empty line.")
       (status CR)
       (qualifier (None))
       (priority Now))))
    ========================
    CR user: Comment may span multiple
    lines too.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:8:9)
         (stop  my_file.ml:9:22)))
       (content_start_offset 195)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:8:12)
               (stop  my_file.ml:8:14)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:8:12)
               (stop  my_file.ml:8:14)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:8:15)
               (stop  my_file.ml:8:19)))))
           (recipient ()))))
       (comment_prefix ";;")
       (digest_of_condensed_content 6f8e9e350677c2f81d33e6a3ec6d588b)
       (content "CR user: Comment may span multiple\n         ;; lines too.")))
     (getters (
       (path my_file.ml)
       (content "CR user: Comment may span multiple\n         ;; lines too.")
       (status CR)
       (qualifier (None))
       (priority Now))))
    ========================
    CR user: Let's cover the case

    Where there are empty lines that are part of the comment.
    This happens when the CR has multiple paragraphs.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:11:2)
         (stop  my_file.ml:15:0)))
       (content_start_offset 259)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:11:5)
               (stop  my_file.ml:11:7)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:11:5)
               (stop  my_file.ml:11:7)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:11:8)
               (stop  my_file.ml:11:12)))))
           (recipient ()))))
       (comment_prefix ";;")
       (digest_of_condensed_content db3e65d596c50205442c2d6b223f1817)
       (content
        "CR user: Let's cover the case\n  ;;\n  ;; Where there are empty lines that are part of the comment.\n  ;; This happens when the CR has multiple paragraphs.")))
     (getters (
       (path my_file.ml)
       (content
        "CR user: Let's cover the case\n  ;;\n  ;; Where there are empty lines that are part of the comment.\n  ;; This happens when the CR has multiple paragraphs.")
       (status CR)
       (qualifier (None))
       (priority Now))))
    |}];
  ()
;;

let%expect_test "xml-style" =
  test
    {|
<!-- $CR user: This is a comment. -->

<!-- $XCR user: And it can
     span multiple lines too. -->

<!-- Hello comment.
  <!-- $XCR user: What happens if it is nested? -->
-->
|};
  [%expect
    {|
    ========================
    CR user: This is a comment.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:1:36)))
       (content_start_offset 5)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:1:5)
               (stop  my_file.ml:1:7)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:1:5)
               (stop  my_file.ml:1:7)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:1:8)
               (stop  my_file.ml:1:12)))))
           (recipient ()))))
       (comment_prefix <!--)
       (digest_of_condensed_content 163bbcea849da7f4b4bc94be0c158f3b)
       (content "CR user: This is a comment.")))
     (getters (
       (path    my_file.ml)
       (content "CR user: This is a comment.")
       (status  CR)
       (qualifier (None))
       (priority Now))))
    ========================
    XCR user: And it can
    span multiple lines too.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:3:0)
         (stop  my_file.ml:4:33)))
       (content_start_offset 43)
       (header (
         Ok (
           (status (
             (txt XCR)
             (loc (
               (start my_file.ml:3:5)
               (stop  my_file.ml:3:8)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:3:5)
               (stop  my_file.ml:3:8)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:3:9)
               (stop  my_file.ml:3:13)))))
           (recipient ()))))
       (comment_prefix <!--)
       (digest_of_condensed_content b0cd03d9b3fa2989b1733e82d73c65cf)
       (content "XCR user: And it can\n     span multiple lines too.")))
     (getters (
       (path my_file.ml)
       (content "XCR user: And it can\n     span multiple lines too.")
       (status XCR)
       (qualifier (None))
       (priority Now))))
    ========================
    XCR user: What happens if it is nested?
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:7:2)
         (stop  my_file.ml:7:50)))
       (content_start_offset 126)
       (header (
         Ok (
           (status (
             (txt XCR)
             (loc (
               (start my_file.ml:7:7)
               (stop  my_file.ml:7:10)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:7:7)
               (stop  my_file.ml:7:10)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:7:11)
               (stop  my_file.ml:7:15)))))
           (recipient ()))))
       (comment_prefix <!--)
       (digest_of_condensed_content 4e6aab504567aa351025b2db16cc21c9)
       (content "XCR user: What happens if it is nested?")))
     (getters (
       (path    my_file.ml)
       (content "XCR user: What happens if it is nested?")
       (status  XCR)
       (qualifier (None))
       (priority Now))))
    |}];
  (* Note a comment in [file_parser.ml] says:

     {v XML    <!-- X?CR ... --> may not nest recursively v}

     However as this test shows, this is one case where a nested comment seems
     to be parsed. Leaving as monitoring test. *)
  ()
;;

let%expect_test "nested-ml-style" =
  test
    {|
(* Hello comment.

   (* $XCR user: CR comment may be nested inside other comment in OCaml. *)

   Perhaps that may be useful when commenting/uncommenting large section
   of code in dev mode?

   Note, this is not a part that is documented, and it may end up changing
   in the future. *)
|};
  [%expect
    {|
    ========================
    XCR user: CR comment may be nested inside other comment in OCaml.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:3:3)
         (stop  my_file.ml:3:74)))
       (content_start_offset 25)
       (header (
         Ok (
           (status (
             (txt XCR)
             (loc (
               (start my_file.ml:3:6)
               (stop  my_file.ml:3:9)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:3:6)
               (stop  my_file.ml:3:9)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:3:10)
               (stop  my_file.ml:3:14)))))
           (recipient ()))))
       (comment_prefix "(*")
       (digest_of_condensed_content eabf2e14ab93e23c865512b2be28ca23)
       (content
        "XCR user: CR comment may be nested inside other comment in OCaml.")))
     (getters (
       (path my_file.ml)
       (content
        "XCR user: CR comment may be nested inside other comment in OCaml.")
       (status XCR)
       (qualifier (None))
       (priority Now))))
    |}];
  test
    {|
(* $CR user: Maybe the original use case is the opposite though.

    That is, a (* comment inside a CR comment. *)

    We'd like to cover this case too. *)
|};
  [%expect
    {|
    ========================
    CR user: Maybe the original use case is the opposite though.

     That is, a (* comment inside a CR comment. *)

     We'd like to cover this case too.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:6:0)))
       (content_start_offset 3)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:1:3)
               (stop  my_file.ml:1:5)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:1:3)
               (stop  my_file.ml:1:5)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:1:6)
               (stop  my_file.ml:1:10)))))
           (recipient ()))))
       (comment_prefix "(*")
       (digest_of_condensed_content 5e02200634a76672a440e5a2a1243b5c)
       (content
        "CR user: Maybe the original use case is the opposite though.\n\n    That is, a (* comment inside a CR comment. *)\n\n    We'd like to cover this case too.")))
     (getters (
       (path my_file.ml)
       (content
        "CR user: Maybe the original use case is the opposite though.\n\n    That is, a (* comment inside a CR comment. *)\n\n    We'd like to cover this case too.")
       (status CR)
       (qualifier (None))
       (priority Now))))
    |}];
  test
    {|
(* $CR user: What happens when nested comments are not well closed?

    With a (* comment inside a CR comment. *)

    We'd like to cover this case too.
|};
  [%expect {||}];
  test
    {|
(* $CR user: And what happens when simple comments are not well closed actually?
|};
  [%expect {||}];
  ()
;;

let%expect_test "not commented" =
  (* These tests help to cover more special cases of the parsing logic, as it
     relates to ignore fragments that look like CRs but are not located within a
     recognized comment section. *)
  test
    {|
* CR user: Hello.
|};
  [%expect {||}];
  test
    {|
** CR user: Hello.
|};
  [%expect {||}];
  test
    {|
;;* CR user: Hello.
|};
  [%expect {||}];
  test
    {|
/ CR user: Hello.
|};
  [%expect {||}];
  test
    {|
- CR user: Hello.
|};
  [%expect {||}];
  test
    {|
Hello / CR user: Hello.
|};
  [%expect {||}];
  test
    {|
Hello - CR user: Hello.
|};
  [%expect {||}];
  ()
;;

let%expect_test "not standard" =
  (* These tests help characterizing the parsing of forms for CRs that are not
     exactly standard, and probably accepted because of certain traits of the
     current implementation. We keep them as monitoring tests, however we should
     discourage their actual use. Currently we do not have a linter to
     invalidate them although we'd like to. This is left as future work. *)
  test
    {|
(* # $CR user: This is recognized as a bash comment even though it is in what
   looks like an OCaml comment. This is probably very confusing. *)
|};
  [%expect
    {|
    ========================
    CR user: This is recognized as a bash comment even though it is in what
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:3)
         (stop  my_file.ml:1:76)))
       (content_start_offset 5)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:1:5)
               (stop  my_file.ml:1:7)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:1:5)
               (stop  my_file.ml:1:7)))))
           (reporter (
             (txt user)
             (loc (
               (start my_file.ml:1:8)
               (stop  my_file.ml:1:12)))))
           (recipient ()))))
       (comment_prefix #)
       (digest_of_condensed_content 8e520533c5daff4051ae5f881ed776fe)
       (content
        "CR user: This is recognized as a bash comment even though it is in what")))
     (getters (
       (path my_file.ml)
       (content
        "CR user: This is recognized as a bash comment even though it is in what")
       (status CR)
       (qualifier (None))
       (priority Now))))
    |}];
  test
    {|
(** $CR user1: A CR in a odoc comment. *)
|};
  [%expect
    {|
    ========================
    CR user1: A CR in a odoc comment.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:2:0)))
       (content_start_offset 4)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:1:4)
               (stop  my_file.ml:1:6)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:1:4)
               (stop  my_file.ml:1:6)))))
           (reporter (
             (txt user1)
             (loc (
               (start my_file.ml:1:7)
               (stop  my_file.ml:1:12)))))
           (recipient ()))))
       (comment_prefix "(**")
       (digest_of_condensed_content cc1af9dd750d28232c0d61baac9d1fd0)
       (content "CR user1: A CR in a odoc comment.")))
     (getters (
       (path    my_file.ml)
       (content "CR user1: A CR in a odoc comment.")
       (status  CR)
       (qualifier (None))
       (priority Now))))
    |}];
  test "(*\tCR user1: A CR with a tab separator. *)";
  [%expect
    {|
    ========================
    CR user1: A CR with a tab separator.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:2:0)))
       (content_start_offset 3)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:1:3)
               (stop  my_file.ml:1:5)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:1:3)
               (stop  my_file.ml:1:5)))))
           (reporter (
             (txt user1)
             (loc (
               (start my_file.ml:1:6)
               (stop  my_file.ml:1:11)))))
           (recipient ()))))
       (comment_prefix "(*")
       (digest_of_condensed_content f003b93b7b5671e78f67a88cbcc5899e)
       (content "CR user1: A CR with a tab separator.")))
     (getters (
       (path    my_file.ml)
       (content "CR user1: A CR with a tab separator.")
       (status  CR)
       (qualifier (None))
       (priority Now))))
    |}];
  test
    {|
(*
     $CR user1: A CR with spaces and newline separators. *)
|};
  [%expect
    {|
    ========================
    CR user1: A CR with spaces and newline separators.
    ((raw (
       (path my_file.ml)
       (whole_loc (
         (start my_file.ml:1:0)
         (stop  my_file.ml:3:0)))
       (content_start_offset 8)
       (header (
         Ok (
           (status (
             (txt CR)
             (loc (
               (start my_file.ml:2:5)
               (stop  my_file.ml:2:7)))))
           (qualifier (
             (txt None)
             (loc (
               (start my_file.ml:2:5)
               (stop  my_file.ml:2:7)))))
           (reporter (
             (txt user1)
             (loc (
               (start my_file.ml:2:8)
               (stop  my_file.ml:2:13)))))
           (recipient ()))))
       (comment_prefix "(*")
       (digest_of_condensed_content 41642e9219efa85542d718c0b59e8e1c)
       (content "CR user1: A CR with spaces and newline separators.")))
     (getters (
       (path my_file.ml)
       (content "CR user1: A CR with spaces and newline separators.")
       (status CR)
       (qualifier (None))
       (priority Now))))
    |}];
  ()
;;
