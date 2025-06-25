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

(*_ This module is derived from Iron (v0.9.114.44+47), file
  * [./hg/cr_comment.mli], which is released under Apache 2.0:
  *
  * Copyright (c) 2016-2017 Jane Street Group, LLC <opensource-contacts@janestreet.com>
  *
  * Licensed under the Apache License, Version 2.0 (the "License"); you may not
  * use this file except in compliance with the License. You may obtain a copy
  * of the License at:
  *
  *     http://www.apache.org/licenses/LICENSE-2.0
  *
  * Unless required by applicable law or agreed to in writing, software
  * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
  * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
  * License for the specific language governing permissions and limitations
  * under the License.
  *
  * See the file `NOTICE.md` at the root of this repository for more details.
  *
  * Changes: ...
  *
  * - Remove dependency to [Core] and [Async].
  * - Remove the [Stable] module - remove the versioning of the code.
  * - Replace [Relpath] by [Vcs.Path_in_repo].
  * - Remove [of_sexp] constructs.
  * - Remove [Cr_comment_format].
  * - Replace [Unresolved_name] by [Vcs.User_handle].
  * - Remove [deriving fields] ppx constructs.
  * - Remove alternate names and aliases resolution.
  * - Remove incremental computation features.
  * - Remove summary tables.
  * - Remove invariant checks.
  * - Use [Vcs] instead of [Hg].
  * - Remove [Crs_due_now_and_soon].
  * - Remove support for extra headers.
  * - Remove support for attributes.
  * - Remove assignee computation (left as external work).
  * - Do not export [Raw].
  * - Rename [Processed] to [Header].
  * - Remove support for printing CRs without their content.
  * - Compute positions and offsets with [Loc].
  * - Add [comment_prefix].
*)

(** Code review comments embedded in source code.

    This module provides the core types and functions for representing and
    manipulating code review comments (CRs) embedded directly in source code
    using a special syntax. A CR captures actionable feedback, metadata, and
    assignment information, supporting workflows for tracking, resolving, and
    managing code review discussions within the codebase. *)

module Digest_hex : sig
  type t [@@deriving compare, equal, sexp_of]

  val to_string : t -> string
  val create : string -> t
end

module Header : sig
  type t [@@deriving equal, sexp_of]

  (** [reporter] is [user] in [CR user...]. *)
  val reporter : t -> Vcs.User_handle.t

  (** [for_] is [user2] in [CR user1 for user2: ...]. Assigning CRs to
      particular users is optional. This returns [None] if that part is left
      out, such as in [CR user1: Comment]. *)
  val for_ : t -> Vcs.User_handle.t option

  val kind : t -> Kind.t

  (** This returns the syntactic due class if present [CR-soon] or [CR-someday].
      If there is no due specifier, this returns [Now]. *)
  val due : t -> Due.t

  module With_loc : sig
    (** These getters allows you to access the position of each elements of the
        CR header. This is meant for tools processing CRs automatically, such
        as CRs rewriters. *)

    (** The location includes the entire reporter username, without the
        surrounding spaces. *)
    val reporter : t -> Vcs.User_handle.t Loc.Txt.t

    (** The location includes the entire assignee username, if it is present,
        without the surrounding spaces. In particular, the location does not
        include the ["for"] keyword itself. *)
    val for_ : t -> Vcs.User_handle.t Loc.Txt.t option

    (** The location includes the entire keyword ["CR"] or ["XCR"] depending on
        the case. It stops right before the following char, that being a space
        or a ['-'] (and thus does not include it). *)
    val kind : t -> Kind.t Loc.Txt.t

    (** When the CR is due [Soon] or [Someday], the location returned starts
        right after the dash separator (but does not include it), and contains
        the entire due keyword. For example, the location will include
        ["soon"] for a [CR-soon]. When the CR is due [Now], there is no
        keyword to attach a location to : conventionally, we return instead
        the location of the CR [kind] in this case. *)
    val due : t -> Due.t Loc.Txt.t

    (** {1 Deprecated}

        The following is deprecated and will be soon annotated as such with ocaml
        alerts. Please migrate, and do not use in new code. *)

    (** This was renamed [reporter]. Hint: Run [ocamlmig migrate]. *)
    val reported_by : t -> Vcs.User_handle.t Loc.Txt.t
    [@@migrate { repl = Rel.reporter }]
  end

  (** {1 Deprecated}

      The following is deprecated and will be soon annotated as such with ocaml
      alerts. Please migrate, and do not use in new code. *)

  (** This was renamed [reporter]. Hint: Run [ocamlmig migrate]. *)
  val reported_by : t -> Vcs.User_handle.t
  [@@migrate { repl = Rel.reporter }]
end

(** A [Cr_comment.t] is an immutable value holding the information and metadata
    about a CR that was parsed from a file. *)
type t [@@deriving equal, sexp_of]

(** {1 Getters} *)

val path : t -> Vcs.Path_in_repo.t

(** [content] is the text of the CR with comment markers removed from the
    beginning and end (if applicable). See also {!reindented_content}. *)
val content : t -> string

(** [whole_loc] is suitable for removal of the entire CR comment. It includes
    the comments boundaries from [path] as well. *)
val whole_loc : t -> Loc.t

val header : t -> Header.t Or_error.t
val kind : t -> Kind.t

(** [due t] is a convenience wrapper to get the [due] property of the CR
    header. This returns [Now] when parsing the header resulted in an error. *)
val due : t -> Due.t

(** [work_on t] represents the expectation as to when work on the CR is meant to
    happen. Is it similar to [due t] except that XCRs are meant to be worked
    on [Now]. *)
val work_on : t -> Due.t

(** This digest is computed such that changes in positions in a file, or changes
    in whitespaces are ignored. It is used by downstream systems to detect
    that two CRs are equivalent, which in turn may affect when a CR is
    active. *)
val digest_ignoring_minor_text_changes : t -> Digest_hex.t

(** {1 Print} *)

(** Show the CR with a line showing the file position. *)
val to_string : t -> string

(** [reindented_content t] returns the content of the CR with leading
    indentation removed or normalized. This is useful for displaying multiple
    CRs together in a unified format, such as in [crs grep]. *)
val reindented_content : t -> string

(** Sorts the supplied list of CRs and outputs it to the supplied out channel,
    separated by newline characters. *)
val output_list : t list -> oc:Out_channel.t -> unit

(** A convenient wrapper for {!output_list} that prints to [stdout]. *)
val print_list : t list -> unit

(** {1 Sort} *)

module For_sorted_output : sig
  type nonrec t = t [@@deriving compare]
end

val sort : t list -> t list

(** {1 Private}

    This module is exported to be used by libraries with strong ties to
    [cr_comment]. Its signature may change in breaking ways at any time without
    prior notice, and outside the guidelines set by semver.

    In particular, the intention here is that CRs may only be created using
    dedicated helpers libraries that are defined in this project, parsing them
    from files in vcs trees. *)

module Private : sig
  type header := Header.t

  module Header : sig
    val create
      :  kind:Kind.t Loc.Txt.t
      -> due:Due.t Loc.Txt.t
      -> reporter:Vcs.User_handle.t Loc.Txt.t
      -> for_:Vcs.User_handle.t Loc.Txt.t option
      -> header
  end

  val create
    :  path:Vcs.Path_in_repo.t
    -> whole_loc:Loc.t
    -> header:header Or_error.t
    -> comment_prefix:string
    -> digest_of_condensed_content:Digest_hex.t
    -> content:string
    -> t
end
