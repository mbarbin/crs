(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

let%expect_test "all" =
  List.iter Cr_comment.Priority.all ~f:(fun priority ->
    print_dyn (Dyn.record [ "priority", priority |> Cr_comment.Priority.to_dyn ]));
  [%expect
    {|
    { priority = Now }
    { priority = Soon }
    { priority = Someday }
    |}];
  ()
;;

let%expect_test "equal" =
  require_equal (module Cr_comment.Priority) Now Now;
  require_not_equal (module Cr_comment.Priority) Now Soon;
  [%expect {||}];
  ()
;;

let%expect_test "compare" =
  print_dyn
    (List.sort
       (List.concat [ List.rev Cr_comment.Priority.all; [ Soon; Now; Someday; Now ] ])
       ~compare:Cr_comment.Priority.compare
     |> Dyn.list Cr_comment.Priority.to_dyn);
  [%expect {| [ Now; Now; Now; Soon; Soon; Someday; Someday ] |}];
  ()
;;
