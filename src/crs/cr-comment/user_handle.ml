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

type t = string

let compare = String.compare
let equal = String.equal
let to_string t = t
let to_dyn = Dyn.string

let is_valid_char = function
  | '0' .. '9' | 'a' .. 'z' | 'A' .. 'Z' | '-' | '_' | '.' | '[' | ']' -> true
  | _ -> false
;;

let invariant t = (not (String.is_empty t)) && String.for_all t ~f:is_valid_char

let of_string str =
  if invariant str
  then Ok str
  else Error (`Msg (Printf.sprintf "%S: invalid user_handle" str))
;;

let v str =
  match of_string str with
  | Ok t -> t
  | Error (`Msg msg) -> invalid_arg msg
;;

let to_json t : Json.t = `String (to_string t)

let of_json json =
  match (json : Json.t) with
  | `String str ->
    (match of_string str with
     | Ok t -> t
     | Error (`Msg msg) -> raise (Json.Error (json, msg)))
  | _ -> raise (Json.Error (json, "User handle expected to be a json string."))
;;
