(*_***************************************************************************)
(*_  ocaml-reviewdog - A reviewdog diagnostics json serializer for OCaml     *)
(*_  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                            *)
(*_***************************************************************************)

type t =
  { start : Position.t
  ; end_ : Position.t option
  }
[@@deriving equal, compare, yojson]
