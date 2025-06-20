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
  List.iter Cr_comment.Filter.all ~f:(fun filter ->
    print_s
      [%sexp
        { filter : Cr_comment.Filter.t
        ; to_string = (Cr_comment.Filter.to_string filter : string)
        ; shorthand = (Cr_comment.Filter.shorthand filter : char)
        }]);
  [%expect
    {|
    ((filter    All)
     (to_string all)
     (shorthand a))
    ((filter    Invalid)
     (to_string invalid)
     (shorthand i))
    ((filter    CRs)
     (to_string crs)
     (shorthand c))
    ((filter    XCRs)
     (to_string xcrs)
     (shorthand x))
    ((filter    Now)
     (to_string now)
     (shorthand w))
    ((filter    Soon)
     (to_string soon)
     (shorthand o))
    ((filter    Someday)
     (to_string someday)
     (shorthand d))
    |}];
  ()
;;

let%expect_test "string count" =
  let count = List.length Cr_comment.Filter.all in
  let string_count =
    Set.of_list
      (module String)
      (List.map Cr_comment.Filter.all ~f:Cr_comment.Filter.to_string)
    |> Set.length
  in
  require_equal [%here] (module Int) count string_count;
  [%expect {||}];
  ()
;;

let%expect_test "shorthand count" =
  let count = List.length Cr_comment.Filter.all in
  let shorthand_count =
    Set.of_list
      (module Char)
      (List.map Cr_comment.Filter.all ~f:Cr_comment.Filter.shorthand)
    |> Set.length
  in
  require_equal [%here] (module Int) count shorthand_count;
  [%expect {||}];
  ()
;;
