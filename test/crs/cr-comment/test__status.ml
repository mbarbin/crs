(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

let%expect_test "to_string" =
  List.iter Cr_comment.Status.all ~f:(fun status ->
    print_dyn
      (Dyn.record
         [ "status", status |> Cr_comment.Status.to_dyn
         ; "to_string", Cr_comment.Status.to_string status |> Dyn.string
         ]));
  [%expect
    {|
    { status = CR; to_string = "CR" }
    { status = XCR; to_string = "XCR" }
    |}];
  ()
;;

let%expect_test "equal" =
  require_equal (module Cr_comment.Status) CR CR;
  require_not_equal (module Cr_comment.Status) CR XCR;
  [%expect {||}];
  ()
;;

let%expect_test "compare" =
  let cr = Cr_comment.Status.CR in
  let xcr = Cr_comment.Status.XCR in
  let computed =
    List.sort
      (List.concat [ List.rev Cr_comment.Status.all; [ xcr; cr; xcr ] ])
      ~compare:Cr_comment.Status.compare
  in
  let expected = [ cr; cr; xcr; xcr; xcr ] in
  let () =
    if not (List.equal Cr_comment.Status.equal computed expected)
    then print_dyn (computed |> Dyn.list Cr_comment.Status.to_dyn) [@coverage off]
  in
  [%expect {||}];
  ()
;;
