(***************************************************************************************)
(*  Crs_stdlib - Extending OCaml's Stdlib for crs                                      *)
(*  SPDX-FileCopyrightText: 2025-2026 Mathieu Barbin <mathieu.barbin@gmail.com>        *)
(*  SPDX-License-Identifier: MIT OR LGPL-3.0-or-later WITH LGPL-3.0-linking-exception  *)
(***************************************************************************************)

let%expect_test "find" =
  print_dyn (Dyn.option Dyn.int (List.find [ 0; 1; 2 ] ~f:(fun i -> i mod 2 = 1)));
  [%expect {| Some 1 |}];
  ()
;;

let%expect_test "hd" =
  print_dyn (Dyn.option Dyn.int (List.hd []));
  [%expect {| None |}];
  print_dyn (Dyn.option Dyn.int (List.hd [ 1 ]));
  [%expect {| Some 1 |}];
  ()
;;
