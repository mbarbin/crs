(***************************************************************************************)
(*  Crs_stdlib - Extending OCaml's Stdlib for crs                                      *)
(*  SPDX-FileCopyrightText: 2025-2026 Mathieu Barbin <mathieu.barbin@gmail.com>        *)
(*  SPDX-License-Identifier: MIT OR LGPL-3.0-or-later WITH LGPL-3.0-linking-exception  *)
(***************************************************************************************)

let%expect_test "to_string_hum" =
  let test i = print_endline (Int.to_string_hum i) in
  test 123;
  [%expect {| 123 |}];
  test (-123);
  [%expect {| -123 |}];
  test (-12);
  [%expect {| -12 |}];
  test 1234;
  [%expect {| 1_234 |}];
  test (-1234);
  [%expect {| -1_234 |}];
  ()
;;
