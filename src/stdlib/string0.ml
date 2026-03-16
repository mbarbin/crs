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

(* Some functions are copied from [Base] version [v0.17] which is released
   under MIT and may be found at [https://github.com/janestreet/base].

   See Base's LICENSE below:

   ----------------------------------------------------------------------------

   The MIT License

   Copyright (c) 2016--2024 Jane Street Group, LLC <opensource-contacts@janestreet.com>

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.

   ----------------------------------------------------------------------------

   When this is the case, we clearly indicate it next to the copied function. *)

include Stdlib.StringLabels

let chop_prefix t ~prefix =
  if starts_with t ~prefix
  then (
    let prefix_len = length prefix in
    Some (StringLabels.sub t ~pos:prefix_len ~len:(length t - prefix_len)))
  else None
;;

let concat t ~sep = concat ~sep t
let is_empty t = length t = 0

let lsplit2 t ~on =
  match index_opt t on with
  | None -> None
  | Some i -> Some (sub t ~pos:0 ~len:i, sub t ~pos:(i + 1) ~len:(length t - i - 1))
;;

let split t ~on = split_on_char ~sep:on t
let strip = trim
let to_dyn = Dyn0.string
let to_string t = t

(* ---------------------------------------------------------------------------- *)
(* The following functions are copied from [Base] (MIT). See notice at the top
   of the file and project global notice for licensing information. *)

let rfindi t ~f =
  let rec loop i = if i < 0 then None else if f i t.[i] then Some i else loop (i - 1) in
  let pos = length t - 1 in
  (loop pos [@nontail])
;;

let last_non_drop ~drop t = rfindi t ~f:(fun _ c -> not (drop c)) [@nontail]

let rstrip ?(drop = Char0.is_whitespace) t =
  match last_non_drop t ~drop with
  | None -> ""
  | Some i -> if i = length t - 1 then t else sub t ~pos:0 ~len:(i + 1)
;;

let lfindi ?(pos = 0) t ~f =
  let n = length t in
  let rec loop i = if i = n then None else if f i t.[i] then Some i else loop (i + 1) in
  (loop pos [@nontail])
;;

let first_non_drop ~drop t = lfindi t ~f:(fun _ c -> not (drop c)) [@nontail]

let lstrip ?(drop = Char0.is_whitespace) t =
  match first_non_drop t ~drop with
  | None -> ""
  | Some 0 -> t
  | Some n -> sub t ~pos:n ~len:(length t - n)
;;

(* ---------------------------------------------------------------------------- *)

(* The function [split_lines] below was copied from [Base.String0.split_lines]
   version [v0.17] which is released under MIT and may be found at
   [https://github.com/janestreet/base].

   The changes we made were minimal:

   - Changed references to [Char0] to [Char].

   See Base's LICENSE below:

   ----------------------------------------------------------------------------

   The MIT License

   Copyright (c) 2016--2024 Jane Street Group, LLC <opensource-contacts@janestreet.com>

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE. *)

let split_lines =
  let back_up_at_newline ~t ~pos ~eol =
    pos := !pos - if !pos > 0 && Char.equal t.[!pos - 1] '\r' then 2 else 1;
    eol := !pos + 1
  in
  fun t ->
    let n = length t in
    if n = 0
    then []
    else (
      (* Invariant: [-1 <= pos < eol]. *)
      let pos = ref (n - 1) in
      let eol = ref n in
      let ac = ref [] in
      (* We treat the end of the string specially, because if the string ends with a
         newline, we don't want an extra empty string at the end of the output. *)
      if Char.equal t.[!pos] '\n' then back_up_at_newline ~t ~pos ~eol;
      while !pos >= 0 do
        if not (Char.equal t.[!pos] '\n')
        then decr pos
        else (
          (* Because [pos < eol], we know that [start <= eol]. *)
          let start = !pos + 1 in
          ac := sub t ~pos:start ~len:(!eol - start) :: !ac;
          back_up_at_newline ~t ~pos ~eol)
      done;
      sub t ~pos:0 ~len:!eol :: !ac)
;;

(* ---------------------------------------------------------------------------- *)

let substr_replace_all t ~pattern ~with_ =
  let pattern_len = length pattern in
  if pattern_len = 0
  then t
  else (
    let t_len = length t in
    let buf = Buffer.create (t_len + (t_len / 2)) in
    let rec loop pos =
      if pos > t_len - pattern_len
      then Buffer.add_substring buf t pos (t_len - pos)
      else (
        let found =
          let rec check i =
            if i = pattern_len
            then true
            else if unsafe_get t (pos + i) = unsafe_get pattern i
            then check (i + 1)
            else false
          in
          check 0
        in
        if found
        then (
          Buffer.add_string buf with_;
          loop (pos + pattern_len))
        else (
          Buffer.add_char buf (unsafe_get t pos);
          loop (pos + 1)))
    in
    loop 0;
    Buffer.contents buf)
;;
