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

type t =
  | CR
  | XCR

let variant_constructor_rank = function
  | CR -> 0
  | XCR -> 1
;;

let compare t1 t2 =
  Int.compare (variant_constructor_rank t1) (variant_constructor_rank t2)
;;

let equal t1 t2 = Int.equal (variant_constructor_rank t1) (variant_constructor_rank t2)
let all = [ CR; XCR ]

let variant_constructor_name = function
  | CR -> "CR"
  | XCR -> "XCR"
;;

let to_dyn t = Dyn.Variant (variant_constructor_name t, [])
let to_string = variant_constructor_name
