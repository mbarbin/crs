(****************************************************************************)
(*  ocaml-reviewdog - A reviewdog diagnostics json serializer for OCaml     *)
(*  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                            *)
(****************************************************************************)

[@@@coverage off]

module Code = struct
  type t = Reviewdog.Code.t =
    { value : string
    ; url : string option
    }
  [@@deriving compare, equal, quickcheck, sexp_of]
end

module Position = struct
  type t = Reviewdog.Position.t =
    { line : int
    ; column : int
    }
  [@@deriving compare, equal, quickcheck, sexp_of]
end

module Range = struct
  type t = Reviewdog.Range.t =
    { start : Position.t
    ; end_ : Position.t option
    }
  [@@deriving compare, equal, quickcheck, sexp_of]
end

module Location = struct
  type t = Reviewdog.Location.t =
    { path : string
    ; range : Range.t option
    }
  [@@deriving compare, equal, quickcheck, sexp_of]
end

module Severity = struct
  type t = Reviewdog.Severity.t =
    | Unknown_severity
    | Error
    | Warning
    | Info
  [@@deriving compare, equal, quickcheck, sexp_of]
end

module Source = struct
  type t = Reviewdog.Source.t =
    { name : string
    ; url : string option
    }
  [@@deriving compare, equal, quickcheck, sexp_of]
end

module Suggestion = struct
  type t = Reviewdog.Suggestion.t =
    { range : Range.t
    ; text : string
    }
  [@@deriving compare, equal, quickcheck, sexp_of]
end

module Related_location = struct
  type t = Reviewdog.Related_location.t =
    { message : string option
    ; location : Location.t
    }
  [@@deriving compare, equal, quickcheck, sexp_of]
end

module Diagnostic = struct
  type t = Reviewdog.Diagnostic.t =
    { message : string
    ; location : Location.t
    ; severity : Severity.t option
    ; source : Source.t option
    ; code : Code.t option
    ; suggestions : Suggestion.t list
    ; original_output : string option
    ; related_locations : Related_location.t list
    }
  [@@deriving compare, equal, quickcheck, sexp_of]
end

module Diagnostic_result = struct
  type t = Reviewdog.Diagnostic_result.t =
    { source : Source.t option
    ; severity : Severity.t option
    ; diagnostics : Diagnostic.t list
    }
  [@@deriving compare, equal, quickcheck, sexp_of]
end
