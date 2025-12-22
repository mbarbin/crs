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

let all = [ Unknown_severity; Error; Warning; Info ]

let to_string = function
  | Unknown_severity -> "UNKNOWN_SEVERITY"
  | Error -> "ERROR"
  | Warning -> "WARNING"
  | Info -> "INFO"
;;

let to_json t : Yojson.Basic.t = `String (to_string t)
