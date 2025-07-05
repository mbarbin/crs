(*_***************************************************************************)
(*_  ocaml-reviewdog - A reviewdog diagnostics json serializer for OCaml     *)
(*_  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                            *)
(*_***************************************************************************)

type t =
  { message : string option
  ; location : Location.t
  }
[@@deriving equal, compare, yojson]
