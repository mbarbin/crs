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

include Stdlib.ListLabels

let equal eq t1 t2 = equal ~eq t1 t2
let exists t ~f = exists ~f t
let filter t ~f = filter ~f t
let filter_map t ~f = filter_map ~f t

(* [filter_mapi] is available in stdlib but only from [5.5]. *)
let[@tail_mod_cons] rec filter_mapi f i = function
  | [] -> []
  | x :: l ->
    let i' = i + 1 in
    (match f i x with
     | None -> filter_mapi f i' l
     | Some v -> v :: filter_mapi f i' l)
;;

let filter_mapi l ~f = filter_mapi f 0 l
let filter_opt t = filter_map t ~f:Fun.id
let find t ~f = find_opt ~f t
let find_exn t ~f = Stdlib.List.find f t
let for_all t ~f = for_all ~f t

(* ---------------------------------------------------------------------------- *)
(* [unzip], [groupi] and [group] are copied from [Base] (MIT). See notice at
   the top of the file and project global notice for licensing information. *)

let unzip list =
  let rec loop list l1 l2 =
    match list with
    | [] -> l1, l2
    | (x, y) :: tl -> loop tl (x :: l1) (y :: l2)
  in
  loop (rev list) [] []
;;

let groupi l ~break =
  (* We allocate shared position and list references so we can make the inner loop use
     [[@tail_mod_cons]], and still return back information about position and where in the
     list we left off. *)
  let pos = ref 0 in
  let l = ref l in
  (* As a result of using local references, our inner loop does not need arguments. *)
  let[@tail_mod_cons] rec take_group () =
    match !l with
    | [] -> assert false
    | [ _ ] as group ->
      l := [];
      group
    | x :: (y :: _ as tl) ->
      pos := !pos + 1;
      l := tl;
      if break !pos x y
      then [ x ]
      else
        (* Coverage is off in the second part of the expression because the
           instrumentation breaks [@tail_mod_cons], triggering warning 71. *)
        x :: (take_group () [@coverage off])
  in
  (* Our outer loop does not need arguments, either. *)
  let[@tail_mod_cons] rec groups () =
    if is_empty !l
    then []
    else (
      let group = take_group () in
      (* Coverage is off in the second part of the expression because the
         instrumentation breaks [@tail_mod_cons], triggering warning 71. *)
      group :: (groups () [@coverage off]))
  in
  (groups () [@nontail])
;;

let group l ~break = groupi l ~break:(fun _ x y -> break x y) [@nontail]
(* ---------------------------------------------------------------------------- *)

let hd = function
  | [] -> None
  | hd :: _ -> Some hd
;;

let hd_exn = Stdlib.List.hd
let iter t ~f = iter ~f t
let map t ~f = map ~f t
let mem t x ~equal = exists t ~f:(fun y -> equal x y)
let sort t ~compare = sort t ~cmp:compare

let sort_and_group t ~compare =
  sort t ~compare |> group ~break:(fun t1 t2 -> 0 <> compare t1 t2)
;;
