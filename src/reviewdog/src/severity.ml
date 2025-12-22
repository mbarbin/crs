(****************************************************************************)
(*  ocaml-reviewdog - A reviewdog diagnostics json serializer for OCaml     *)
(*  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                            *)
(****************************************************************************)

type t =
  | Unknown_severity
  | Error
  | Warning
  | Info
[@@deriving compare, equal, enumerate]

let of_string = function
  | "UNKNOWN_SEVERITY" -> Ok Unknown_severity
  | "ERROR" -> Ok Error
  | "WARNING" -> Ok Warning
  | "INFO" -> Ok Info
  | str -> Error (Printf.sprintf "Invalid severity: %s" str)
;;

let to_string = function
  | Unknown_severity -> "UNKNOWN_SEVERITY"
  | Error -> "ERROR"
  | Warning -> "WARNING"
  | Info -> "INFO"
;;

let to_yojson t = `String (to_string t)

let of_yojson json =
  match (json : Yojson.Safe.t) with
  | `String str | `List [ `String str ] -> of_string str
  | json -> Error (Printf.sprintf "Invalid severity: %s" (Yojson.Safe.to_string json))
;;
