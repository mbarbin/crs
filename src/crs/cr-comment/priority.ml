(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

type t =
  | Now
  | Soon
  | Someday

let variant_constructor_rank = function
  | Now -> 0
  | Soon -> 1
  | Someday -> 2
;;

let compare t1 t2 =
  Int.compare (variant_constructor_rank t1) (variant_constructor_rank t2)
;;

let equal t1 t2 = Int.equal (variant_constructor_rank t1) (variant_constructor_rank t2)
let all = [ Now; Soon; Someday ]

let variant_constructor_name = function
  | Now -> "Now"
  | Soon -> "Soon"
  | Someday -> "Someday"
;;

let to_dyn t = Dyn.Variant (variant_constructor_name t, [])
