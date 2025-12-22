(****************************************************************************)
(*  ocaml-reviewdog - A reviewdog diagnostics json serializer for OCaml     *)
(*  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                            *)
(****************************************************************************)

type t =
  { range : Range.t
  ; text : string
  }

let to_json { range; text } : Yojson.Basic.t =
  `Assoc [ "range", Range.to_json range; "text", `String text ]
;;
