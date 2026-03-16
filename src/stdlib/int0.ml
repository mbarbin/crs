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
