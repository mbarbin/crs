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

let%expect_test "all" =
  List.iter Cr_comment.Qualifier.all ~f:(fun qualifier ->
    let priority = Cr_comment.Qualifier.priority qualifier in
    print_s
      [%sexp { qualifier : Cr_comment.Qualifier.t; priority : Cr_comment.Priority.t }]);
  [%expect
    {|
    ((qualifier None)
     (priority  Now))
    ((qualifier Soon)
     (priority  Soon))
    ((qualifier Someday)
     (priority  Someday))
    |}];
  ()
;;

let%expect_test "equal" =
  require_equal [%here] (module Cr_comment.Qualifier) None None;
  require_not_equal [%here] (module Cr_comment.Qualifier) None Soon;
  [%expect {||}];
  ()
;;

let%expect_test "compare" =
  print_s
    [%sexp
      (List.sort
         (List.concat
            [ List.rev Cr_comment.Qualifier.all; [ Soon; None; Someday; None ] ])
         ~compare:Cr_comment.Qualifier.compare
       : Cr_comment.Qualifier.t list)];
  [%expect {| (None None None Soon Soon Someday Someday) |}];
  ()
;;
