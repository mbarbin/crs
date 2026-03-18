(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

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
