(*_*******************************************************************************)
(*_  crs - A tool for managing code review comments embedded in source code      *)
(*_  Copyright (C) 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>           *)
(*_                                                                              *)
(*_  This file is part of crs.                                                   *)
(*_                                                                              *)
(*_  crs is free software; you can redistribute it and/or modify it under the    *)
(*_  terms of the GNU Lesser General Public License as published by the Free     *)
(*_  Software Foundation either version 3 of the License, or any later version,  *)
(*_  with the LGPL-3.0 Linking Exception.                                        *)
(*_                                                                              *)
(*_  crs is distributed in the hope that it will be useful, but WITHOUT ANY      *)
(*_  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS   *)
(*_  FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License and     *)
(*_  the file `NOTICE.md` at the root of this repository for more details.       *)
(*_                                                                              *)
(*_  You should have received a copy of the GNU Lesser General Public License    *)
(*_  and the LGPL-3.0 Linking Exception along with this library. If not, see     *)
(*_  <http://www.gnu.org/licenses/> and <https://spdx.org>, respectively.        *)
(*_*******************************************************************************)

(** A module to help managing invalid CRs.

    Sometimes during parsing we find comments fragments that kind of look like
    CRs, but are not quite valid ones. In this case, we need to decide what to
    do. On one hand we'd like to draw the attention of reviewers on fragments
    that we think are probably CRs, so they can fix them, and address them. On
    the other hand, we'd like to avoid noisy false positive, and thus we must
    ignore fragments that are too unlikely to be actual CRs.

    This is not a perfect process, and we make use of some heuristics and
    opinionated choices in this implementation. The behavior is characterized
    precisely in the test suite, for reference. *)

module Invalid_cr : sig
  (** A type to hold information extracted from an invalid CR. If the CR is "so"
      invalid that we don't even want to consider it as such, such [t] is never
      built (and the "not-a-CR" should simply be ignored then). *)
  type t

  (** {1 Getters}

      Note that because we are more permissive in what invalid headers are allowed
      to parse, most getters return untyped values (string). Not being able to
      validate a particular username for example (due to it containing an invalid
      character or something) could be a reason why the CR is invalid. *)

  val status : t -> Cr_comment.Status.t Loc.Txt.t
  val qualifier : t -> string Loc.Txt.t option
  val reporter : t -> string Loc.Txt.t option
  val for_or_to : t -> string Loc.Txt.t option
  val recipient : t -> string Loc.Txt.t option
  val contents : t -> string Loc.Txt.t
end

(** {1 Parse} *)

module Maybe_invalid_cr : sig
  type t =
    | Invalid_cr of Invalid_cr.t
    | Not_a_cr
end

val parse
  :  file_cache:Loc.File_cache.t
  -> content_start_offset:Loc.Offset.t
  -> content:string
  -> Maybe_invalid_cr.t
