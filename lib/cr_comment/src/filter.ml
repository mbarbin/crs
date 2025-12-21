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
  | All
  | Invalid
  | CRs
  | XCRs
  | Now
  | Soon
  | Someday
[@@deriving compare, equal, enumerate]

let variant_constructor_name = function
  | All -> "All"
  | Invalid -> "Invalid"
  | CRs -> "CRs"
  | XCRs -> "XCRs"
  | Now -> "Now"
  | Soon -> "Soon"
  | Someday -> "Someday"
;;

let to_dyn t = Dyn.Variant (variant_constructor_name t, [])
let sexp_of_t t = Sexp.Atom (variant_constructor_name t)
let to_string t = String.lowercase (variant_constructor_name t)

let shorthand = function
  | All -> 'a'
  | Invalid -> 'i'
  | CRs -> 'c'
  | XCRs -> 'x'
  | Now -> 'w'
  | Soon -> 'o'
  | Someday -> 'd'
;;

let matches t ~cr =
  match t with
  | All -> true
  | Invalid ->
    (match Cr_comment0.header cr with
     | Error _ -> true
     | Ok _ -> false)
  | CRs ->
    (match Cr_comment0.header cr with
     | Error _ -> false
     | Ok h ->
       (match Cr_comment0.Header.status h with
        | XCR -> false
        | CR ->
          (match Cr_comment0.Header.qualifier h with
           | None -> true
           | Soon | Someday -> false)))
  | XCRs ->
    (match Cr_comment0.header cr with
     | Error _ -> false
     | Ok h ->
       (match Cr_comment0.Header.status h with
        | CR -> false
        | XCR -> true))
  | Now ->
    (match Cr_comment0.header cr with
     | Error _ -> false
     | Ok h ->
       (match Cr_comment0.Header.status h with
        | XCR -> true
        | CR ->
          (match Cr_comment0.Header.qualifier h with
           | None -> true
           | Soon | Someday -> false)))
  | Soon ->
    (match Cr_comment0.header cr with
     | Error _ -> false
     | Ok h ->
       (match Cr_comment0.Header.status h with
        | XCR -> false
        | CR ->
          (match Cr_comment0.Header.qualifier h with
           | Soon -> true
           | None | Someday -> false)))
  | Someday ->
    (match Cr_comment0.header cr with
     | Error _ -> false
     | Ok h ->
       (match Cr_comment0.Header.status h with
        | XCR -> false
        | CR ->
          (match Cr_comment0.Header.qualifier h with
           | Someday -> true
           | None | Soon -> false)))
;;
