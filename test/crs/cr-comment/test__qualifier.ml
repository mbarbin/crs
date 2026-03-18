(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

let%expect_test "all" =
  List.iter Cr_comment.Qualifier.all ~f:(fun qualifier ->
    let priority = Cr_comment.Qualifier.priority qualifier in
    print_dyn
      (Dyn.record
         [ "qualifier", qualifier |> Cr_comment.Qualifier.to_dyn
         ; "priority", priority |> Cr_comment.Priority.to_dyn
         ]));
  [%expect
    {|
    { qualifier = None; priority = Now }
    { qualifier = Soon; priority = Soon }
    { qualifier = Someday; priority = Someday }
    |}];
  ()
;;

let%expect_test "equal" =
  require_equal (module Cr_comment.Qualifier) None None;
  require_not_equal (module Cr_comment.Qualifier) None Soon;
  [%expect {||}];
  ()
;;

let%expect_test "compare" =
  print_dyn
    (List.sort
       (List.concat [ List.rev Cr_comment.Qualifier.all; [ Soon; None; Someday; None ] ])
       ~compare:Cr_comment.Qualifier.compare
     |> Dyn.list Cr_comment.Qualifier.to_dyn);
  [%expect {| [ None; None; None; Soon; Soon; Someday; Someday ] |}];
  ()
;;
