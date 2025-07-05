(****************************************************************************)
(*  ocaml-reviewdog - A reviewdog diagnostics json serializer for OCaml     *)
(*  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                            *)
(****************************************************************************)

type t =
  { message : string
  ; location : Location.t
  ; severity : Severity.t option [@yojson.option]
  ; source : Source.t option [@yojson.option]
  ; code : Code.t option [@yojson.option]
  ; suggestions : Suggestion.t list option [@yojson.option]
  ; original_output : string option [@yojson.option] [@key "originalOutput"]
  ; related_locations : Related_location.t list option
        [@yojson.option] [@key "relatedLocations"]
  }
[@@deriving equal, compare, yojson]
