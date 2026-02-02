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

let%expect_test "lstrip" =
  let test s = print_dyn (Dyn.string (String.lstrip s)) in
  test "";
  [%expect {| "" |}];
  test "123  ";
  [%expect {| "123  " |}];
  test "  123";
  [%expect {| "123" |}];
  ()
;;

let%expect_test "rstrip" =
  let test s = print_dyn (Dyn.string (String.rstrip s)) in
  test "";
  [%expect {| "" |}];
  test "123  ";
  [%expect {| "123" |}];
  test "  123";
  [%expect {| "  123" |}];
  ()
;;

let%expect_test "substr_replace_all" =
  let test t ~pattern =
    print_dyn (Dyn.string (String.substr_replace_all t ~pattern ~with_:"XXX"))
  in
  test "" ~pattern:"";
  [%expect {| "" |}];
  test "hello" ~pattern:"";
  [%expect {| "hello" |}];
  test "hello" ~pattern:"lo";
  [%expect {| "helXXX" |}];
  test "hello, hello" ~pattern:"lo";
  [%expect {| "helXXX, helXXX" |}];
  ()
;;

let%expect_test "split_lines" =
  let test t = print_dyn (Dyn.list Dyn.string (String.split_lines t)) in
  test "";
  [%expect {| [] |}];
  test "hello\nworld";
  [%expect {| [ "hello"; "world" ] |}];
  test "hello\r\nworld\r\n";
  [%expect {| [ "hello"; "world" ] |}];
  ()
;;
