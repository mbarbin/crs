(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

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
