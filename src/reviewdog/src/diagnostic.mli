(*_***************************************************************************)
(*_  ocaml-reviewdog - A reviewdog diagnostics json serializer for OCaml     *)
(*_  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                            *)
(*_***************************************************************************)

type t =
  { message : string
  ; location : Location.t
  ; severity : Severity.t option
  ; source : Source.t option
  ; code : Code.t option
  ; suggestions : Suggestion.t list
  ; original_output : string option
  ; related_locations : Related_location.t list
  }
[@@deriving equal, compare, yojson]
