(***************************************************************************************)
(*  Crs_stdlib - Extending OCaml's Stdlib for crs                                      *)
(*  SPDX-FileCopyrightText: 2025-2026 Mathieu Barbin <mathieu.barbin@gmail.com>        *)
(*  SPDX-License-Identifier: MIT OR LGPL-3.0-or-later WITH LGPL-3.0-linking-exception  *)
(***************************************************************************************)

let%expect_test "is_whitespace" =
  require (List.for_all [ ' '; '\t'; '\011'; '\012'; '\r' ] ~f:Char.is_whitespace);
  [%expect {||}];
  ()
;;
