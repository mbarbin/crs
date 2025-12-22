(****************************************************************************)
(*  ocaml-reviewdog - A reviewdog diagnostics json serializer for OCaml     *)
(*  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                            *)
(****************************************************************************)

type t =
  { line : int
  ; column : int
  }

let to_json { line; column } : Yojson.Basic.t =
  `Assoc [ "line", `Int line; "column", `Int column ]
;;
