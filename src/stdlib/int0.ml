(***************************************************************************************)
(*  Crs_stdlib - Extending OCaml's Stdlib for crs                                      *)
(*  SPDX-FileCopyrightText: 2025-2026 Mathieu Barbin <mathieu.barbin@gmail.com>        *)
(*  SPDX-License-Identifier: MIT OR LGPL-3.0-or-later WITH LGPL-3.0-linking-exception  *)
(***************************************************************************************)

include Stdlib.Int

let incr = Stdlib.incr
let to_dyn = Dyn0.int

let to_string_hum n =
  let s = string_of_int n in
  let len = String.length s in
  let is_negative = n < 0 in
  let sign_count = if is_negative then 1 else 0 in
  let absolute_digit_count = if is_negative then len - 1 else len in
  let separator_count = absolute_digit_count / 3 in
  let initial_skip_count =
    let digit_skip = absolute_digit_count mod 3 in
    sign_count + if digit_skip > 0 then digit_skip else 3
  in
  let buffer = Buffer.create (len + separator_count) in
  let rec aux i count =
    if i < len
    then
      if count = 0
      then (
        Buffer.add_char buffer '_';
        aux i 3)
      else (
        Buffer.add_char buffer s.[i];
        aux (i + 1) (count - 1))
  in
  aux 0 initial_skip_count;
  Buffer.contents buffer
;;
