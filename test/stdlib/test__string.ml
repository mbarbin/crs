(***************************************************************************************)
(*  Crs_stdlib - Extending OCaml's Stdlib for crs                                      *)
(*  SPDX-FileCopyrightText: 2025-2026 Mathieu Barbin <mathieu.barbin@gmail.com>        *)
(*  SPDX-License-Identifier: MIT OR LGPL-3.0-or-later WITH LGPL-3.0-linking-exception  *)
(***************************************************************************************)

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
