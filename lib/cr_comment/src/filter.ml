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

type t =
  | Invalid
  | CRs
  | XCRs
  | Now
  | Soon
  | Someday
[@@deriving compare, equal, enumerate, sexp_of]

let to_string = function
  | (Invalid | CRs | XCRs | Now | Soon | Someday) as t ->
    (match sexp_of_t t with
     | Atom str -> String.lowercase str
     | List _ -> assert false)
;;

let shorthand = function
  | Invalid -> 'i'
  | CRs -> 'c'
  | XCRs -> 'x'
  | Now -> 'n'
  | Soon -> 'o'
  | Someday -> 'd'
;;
