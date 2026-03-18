(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

let path = Vcs.Path_in_repo.v "my_file.ml"

let test file_contents =
  let crs = Tests_helpers.parse_file ~path ~file_contents in
  List.iter crs ~f:(fun cr ->
    let priority = Cr_comment.priority cr in
    let priority_via_header =
      match Cr_comment.header cr with
      | Error _ -> Cr_comment.Priority.Now
      | Ok h -> Cr_comment.Header.priority h
    in
    require_equal (module Cr_comment.Priority) priority priority_via_header;
    print_endline "========================";
    print_endline (Cr_comment.reindented_content cr);
    print_dyn (Dyn.record [ "priority", priority |> Cr_comment.Priority.to_dyn ]))
;;

let%expect_test "test-cases" =
  test Tests_helpers.test_cases;
  [%expect
    {|
    ========================
    CR user: Hello.
    { priority = Now }
    ========================
    CR user for user2: Hello.
    { priority = Now }
    ========================
    XCR user: Hello.
    { priority = Now }
    ========================
    XCR user for user2: Hello.
    { priority = Now }
    ========================
    CR-user: Invalid.
    { priority = Now }
    ========================
    XCR-user: Invalid.
    { priority = Now }
    ========================
    CR-soon user: Hello.
    { priority = Soon }
    ========================
    CR-someday user: Hello.
    { priority = Someday }
    ========================
    XCR-soon user: Hello.
    { priority = Now }
    ========================
    XCR-someday user: Hello.
    { priority = Now }
    |}];
  ()
;;
