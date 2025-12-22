(****************************************************************************)
(*  ocaml-reviewdog - A reviewdog diagnostics json serializer for OCaml     *)
(*  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                            *)
(****************************************************************************)

type t =
  { message : string
  ; location : Location.t
  ; severity : Severity.t option [@yojson.default None]
  ; source : Source.t option [@yojson.default None]
  ; code : Code.t option [@yojson.default None]
  ; suggestions : Suggestion.t list [@yojson.default []]
  ; original_output : string option [@yojson.default None] [@key "originalOutput"]
  ; related_locations : Related_location.t list
        [@yojson.default []] [@key "relatedLocations"]
  }
[@@deriving equal, compare, yojson]
