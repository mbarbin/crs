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
