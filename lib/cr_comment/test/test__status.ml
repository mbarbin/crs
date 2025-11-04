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

let%expect_test "to_string" =
  List.iter Cr_comment.Status.all ~f:(fun status ->
    print_s
      [%sexp
        { status : Cr_comment.Status.t
        ; to_string = (Cr_comment.Status.to_string status : string)
        }]);
  [%expect
    {|
    ((status    CR)
     (to_string CR))
    ((status    XCR)
     (to_string XCR))
    |}];
  ()
;;

let%expect_test "equal" =
  require_equal [%here] (module Cr_comment.Status) CR CR;
  require_not_equal [%here] (module Cr_comment.Status) CR XCR;
  [%expect {||}];
  ()
;;

let%expect_test "compare" =
  let cr = Cr_comment.Status.CR in
  let xcr = Cr_comment.Status.XCR in
  print_s
    [%sexp
      (List.sort
         (List.concat [ List.rev Cr_comment.Status.all; [ xcr; cr; xcr ] ])
         ~compare:Cr_comment.Status.compare
       : Cr_comment.Status.t list)];
  [%expect {| (CR CR XCR XCR XCR) |}];
  ()
;;
