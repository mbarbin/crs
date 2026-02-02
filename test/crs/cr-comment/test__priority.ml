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
