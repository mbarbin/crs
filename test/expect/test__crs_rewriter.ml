(********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code    *)
(*  Copyright (C) 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>           *)
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

(* In this test we perform various codemods to CR messages, in order to exercise
   the parsing of positions, and to ensure that enough information is indeed
   available in the representation of CRs in order to build refactoring tools
   that manipulate large quantities of CRs automatically. *)

let path = Vcs.Path_in_repo.v "my_file.ml"
let test file_contents ~f = Tests_helpers.test ~path ~file_contents ~f

let%expect_test "remove CR entirely" =
  let file_contents =
    {|
let () =
  (* $CR jdoe: This will be removed. *)
  ()
;;

(* $XCR jdoe: This too *)
let () = ()

(* $CR-jdoe: Invalid CRs are removed too. *)
let () = ()
|}
  in
  test file_contents ~f:(fun ~crs ~file_rewriter ->
    List.iter crs ~f:(fun cr ->
      File_rewriter.remove file_rewriter ~range:(Loc.range (Cr_comment.whole_loc cr))));
  [%expect
    {|
    -1,11 +1,11

      let () =
    -|  (* $CR jdoe: This will be removed. *)
        ()
      ;;

    -|(* $XCR jdoe: This too *)
      let () = ()

    -|(* $CR-jdoe: Invalid CRs are removed too. *)
      let () = ()
    |}];
  ()
;;

let%expect_test "switch CR and XCRs" =
  let file_contents =
    {|
let () =
  (* $CR user1: Message *)
  ()
;;

(* $XCR jdoe for user1: This other message *)
let () = ()
|}
  in
  test file_contents ~f:(fun ~crs ~file_rewriter ->
    List.iter crs ~f:(fun cr ->
      Result.iter (Cr_comment.header cr) ~f:(fun p ->
        let text =
          match Cr_comment.Header.status p with
          | CR -> "XCR"
          | XCR -> "CR"
        in
        File_rewriter.replace
          file_rewriter
          ~range:(Loc.range (Cr_comment.Header.With_loc.status p).loc)
          ~text)));
  [%expect
    {|
    -1,8 +1,8

      let () =
    -|  (* $CR user1: Message *)
    +|  (* $XCR user1: Message *)
        ()
      ;;

    -|(* $XCR jdoe for user1: This other message *)
    +|(* $CR jdoe for user1: This other message *)
      let () = () |}];
  ()
;;

let%expect_test "remove assignees" =
  let file_contents =
    {|
let () =
  (* $CR user1: Message *)
  ()
;;

(* $XCR jdoe for user1: This other message *)
let () = ()

(* $CR user1 for user2: This third message *)
let () = ()
|}
  in
  test file_contents ~f:(fun ~crs ~file_rewriter ->
    List.iter crs ~f:(fun cr ->
      Result.iter (Cr_comment.header cr) ~f:(fun p ->
        match Cr_comment.Header.With_loc.recipient p with
        | None -> ()
        | Some { loc; _ } ->
          File_rewriter.remove
            file_rewriter
            ~range:
              { start = Loc.stop_offset (Cr_comment.Header.With_loc.reporter p).loc
              ; stop = Loc.stop_offset loc
              })));
  [%expect
    {|
    -4,8 +4,8
        ()
      ;;

    -|(* $XCR jdoe for user1: This other message *)
    +|(* $XCR jdoe: This other message *)
      let () = ()

    -|(* $CR user1 for user2: This third message *)
    +|(* $CR user1: This third message *)
      let () = ()
    |}];
  ()
;;

let%expect_test "adding assignees" =
  let file_contents =
    {|
let () =
  (* $CR user1: Message *)
  ()
;;

let () =
  (* $CR user1 for user2: Message *)
  ()
;;

(* $XCR jdoe: This other message *)
let () = ()

(* $CR user1: This third message *)
let () = ()
|}
  in
  test file_contents ~f:(fun ~crs ~file_rewriter ->
    List.iter crs ~f:(fun cr ->
      Result.iter (Cr_comment.header cr) ~f:(fun p ->
        match Cr_comment.Header.recipient p with
        | Some _ -> ()
        | None ->
          File_rewriter.insert
            file_rewriter
            ~offset:(Loc.stop_offset (Cr_comment.Header.With_loc.reporter p).loc)
            ~text:" for assignee")));
  [%expect
    {|
    -1,6 +1,6

      let () =
    -|  (* $CR user1: Message *)
    +|  (* $CR user1 for assignee: Message *)
        ()
      ;;

    -9,8 +9,8
        ()
      ;;

    -|(* $XCR jdoe: This other message *)
    +|(* $XCR jdoe for assignee: This other message *)
      let () = ()

    -|(* $CR user1: This third message *)
    +|(* $CR user1 for assignee: This third message *)
      let () = ()
    |}];
  ()
;;

let%expect_test "change assignees" =
  let file_contents =
    {|
let () =
  (* $CR user1: Message *)
  ()
;;

(* $XCR jdoe for user1: This other message *)
let () = ()

(* $CR user1 for user2: This third message *)
let () = ()
|}
  in
  test file_contents ~f:(fun ~crs ~file_rewriter ->
    let user1 = User_handle.v "user1" in
    let other = User_handle.v "other" in
    List.iter crs ~f:(fun cr ->
      Result.iter (Cr_comment.header cr) ~f:(fun p ->
        let reporter = Cr_comment.Header.With_loc.reporter p in
        if User_handle.equal reporter.txt user1
        then
          File_rewriter.replace
            file_rewriter
            ~range:(Loc.range reporter.loc)
            ~text:(User_handle.to_string other);
        Option.iter (Cr_comment.Header.With_loc.recipient p) ~f:(fun { txt; loc } ->
          if User_handle.equal txt user1
          then
            File_rewriter.replace
              file_rewriter
              ~range:(Loc.range loc)
              ~text:(User_handle.to_string other)))));
  [%expect
    {|
    -1,11 +1,11

      let () =
    -|  (* $CR user1: Message *)
    +|  (* $CR other: Message *)
        ()
      ;;

    -|(* $XCR jdoe for user1: This other message *)
    +|(* $XCR jdoe for other: This other message *)
      let () = ()

    -|(* $CR user1 for user2: This third message *)
    +|(* $CR other for user2: This third message *)
      let () = () |}];
  ()
;;

let%expect_test "change priority now to soon" =
  let file_contents =
    {|
let () =
  (* $CR user1: Message *)
  ()
;;

let () =
  (* $CR user1 for user2: Message *)
  ()
;;

(* $XCR jdoe: This other message *)
let () = ()

(* $CR-someday user1: This third message *)
let () = ()

let () =
  (* $CR-soon user1: Message *)
  ()
;;
|}
  in
  test file_contents ~f:(fun ~crs ~file_rewriter ->
    List.iter crs ~f:(fun cr ->
      Result.iter (Cr_comment.header cr) ~f:(fun p ->
        match Cr_comment.Header.status p with
        | XCR -> ()
        | CR ->
          (match Cr_comment.Header.With_loc.qualifier p with
           | { txt = Soon | Someday; loc = _ } -> ()
           | { txt = None; loc } ->
             File_rewriter.insert
               file_rewriter
               ~offset:(Loc.stop_offset loc)
               ~text:"-soon"))));
  [%expect
    {|
    -1,11 +1,11

      let () =
    -|  (* $CR user1: Message *)
    +|  (* $CR-soon user1: Message *)
        ()
      ;;

      let () =
    -|  (* $CR user1 for user2: Message *)
    +|  (* $CR-soon user1 for user2: Message *)
        ()
      ;;
    |}];
  ()
;;

let%expect_test "change priority soon to someday" =
  let file_contents =
    {|
let () =
  (* $CR user1: Message *)
  ()
;;

let () =
  (* $CR-soon user1 for user2: Message *)
  ()
;;

(* $XCR-soon jdoe: This other message *)
let () = ()

(* $XCR jdoe: This other message *)
let () = ()

(* $CR-someday user1: This third message *)
let () = ()
|}
  in
  test file_contents ~f:(fun ~crs ~file_rewriter ->
    List.iter crs ~f:(fun cr ->
      Result.iter (Cr_comment.header cr) ~f:(fun p ->
        match Cr_comment.Header.status p with
        | XCR -> ()
        | CR ->
          (match Cr_comment.Header.With_loc.qualifier p with
           | { txt = None | Someday; loc = _ } -> ()
           | { txt = Soon; loc } ->
             File_rewriter.replace file_rewriter ~range:(Loc.range loc) ~text:"someday"))));
  [%expect
    {|
    -5,7 +5,7
      ;;

      let () =
    -|  (* $CR-soon user1 for user2: Message *)
    +|  (* $CR-someday user1 for user2: Message *)
        ()
      ;;
    |}];
  ()
;;

let%expect_test "everything due now" =
  let file_contents =
    {|
let () =
  (* $CR user1: Message *)
  ()
;;

let () =
  (* $CR-soon user1 for user2: Message *)
  ()
;;

(* $XCR-soon jdoe: This other message *)
let () = ()

(* $XCR jdoe: This other message *)
let () = ()

(* $CR-someday user1: This third message *)
let () = ()
|}
  in
  test file_contents ~f:(fun ~crs ~file_rewriter ->
    List.iter crs ~f:(fun cr ->
      Result.iter (Cr_comment.header cr) ~f:(fun p ->
        match Cr_comment.Header.With_loc.qualifier p with
        | { txt = None; loc = _ } -> ()
        | { txt = Soon | Someday; loc } ->
          File_rewriter.remove
            file_rewriter
            ~range:
              { start = Loc.stop_offset (Cr_comment.Header.With_loc.status p).loc
              ; stop = Loc.stop_offset loc
              })));
  [%expect
    {|
    -5,15 +5,15
      ;;

      let () =
    -|  (* $CR-soon user1 for user2: Message *)
    +|  (* $CR user1 for user2: Message *)
        ()
      ;;

    -|(* $XCR-soon jdoe: This other message *)
    +|(* $XCR jdoe: This other message *)
      let () = ()

      (* $XCR jdoe: This other message *)
      let () = ()

    -|(* $CR-someday user1: This third message *)
    +|(* $CR user1: This third message *)
      let () = ()
    |}];
  ()
;;
