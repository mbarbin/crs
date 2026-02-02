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

include Dyn

let inline_record cons fields = Dyn.variant cons [ Dyn.record fields ]

module type Stringable_S = sig
  type t

  val to_string : t -> string
end

let stringable (type a) (module M : Stringable_S with type t = a) (a : a) =
  Dyn.string (M.to_string a)
;;

let to_sexp =
  let module Sexp = Sexplib0.Sexp in
  let module S = Sexplib0.Sexp_conv in
  let rec aux (dyn : Dyn.t) : Sexp.t =
    match[@coverage off] dyn with
    | Opaque -> Atom "<opaque>"
    | Unit -> List []
    | Int i -> S.sexp_of_int i
    | Int32 i -> S.sexp_of_int32 i
    | Record fields ->
      List (List.map (fun (field, t) -> Sexp.List [ Atom field; aux t ]) fields)
    | Variant (v, args) ->
      (* Special pretty print of variants holding records. *)
      (match args with
       | [] -> Atom v
       | [ Record fields ] ->
         List
           (Atom v :: List.map (fun (field, t) -> Sexp.List [ Atom field; aux t ]) fields)
       | _ -> List (Atom v :: List.map aux args))
    | Bool b -> S.sexp_of_bool b
    | String a -> S.sexp_of_string a
    | Bytes a -> S.sexp_of_bytes a
    | Int64 i -> S.sexp_of_int64 i
    | Nativeint i -> S.sexp_of_nativeint i
    | Char c -> S.sexp_of_char c
    | Float f -> S.sexp_of_float f
    | Option o -> S.sexp_of_option aux o
    | List l -> S.sexp_of_list aux l
    | Array a -> S.sexp_of_array aux a
    | Tuple t -> List (List.map aux t)
    | Map m -> List (List.map (fun (k, v) -> Sexp.List [ aux k; aux v ]) m)
    | Set s -> List (List.map aux s)
  in
  aux
;;
