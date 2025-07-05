(*_***************************************************************************)
(*_  ocaml-reviewdog - A reviewdog diagnostics json serializer for OCaml     *)
(*_  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                            *)
(*_***************************************************************************)

(** Adding support for [quickcheck] to the reviewdog types. *)

module Code : sig
  type t = Reviewdog.Code.t =
    { value : string
    ; url : string option
    }
  [@@deriving compare, equal, quickcheck, sexp_of]
end

module Position : sig
  type t = Reviewdog.Position.t =
    { line : int
    ; column : int
    }
  [@@deriving compare, equal, quickcheck, sexp_of]
end

module Range : sig
  type t = Reviewdog.Range.t =
    { start : Position.t
    ; end_ : Position.t option
    }
  [@@deriving compare, equal, quickcheck, sexp_of]
end

module Location : sig
  type t = Reviewdog.Location.t =
    { path : string
    ; range : Range.t option
    }
  [@@deriving compare, equal, quickcheck, sexp_of]
end

module Severity : sig
  type t = Reviewdog.Severity.t =
    | Unknown_severity
    | Error
    | Warning
    | Info
  [@@deriving compare, equal, quickcheck, sexp_of]
end

module Source : sig
  type t = Reviewdog.Source.t =
    { name : string
    ; url : string option
    }
  [@@deriving compare, equal, quickcheck, sexp_of]
end

module Suggestion : sig
  type t = Reviewdog.Suggestion.t =
    { range : Range.t
    ; text : string
    }
  [@@deriving compare, equal, quickcheck, sexp_of]
end

module Related_location : sig
  type t = Reviewdog.Related_location.t =
    { message : string option
    ; location : Location.t
    }
  [@@deriving compare, equal, quickcheck, sexp_of]
end

module Diagnostic : sig
  type t = Reviewdog.Diagnostic.t =
    { message : string
    ; location : Location.t
    ; severity : Severity.t option
    ; source : Source.t option
    ; code : Code.t option
    ; suggestions : Suggestion.t list option
    ; original_output : string option
    ; related_locations : Related_location.t list option
    }
  [@@deriving compare, equal, quickcheck, sexp_of]
end

module Diagnostic_result : sig
  type t = Reviewdog.Diagnostic_result.t =
    { source : Source.t option
    ; severity : Severity.t option
    ; diagnostics : Diagnostic.t list
    }
  [@@deriving compare, equal, quickcheck, sexp_of]
end
