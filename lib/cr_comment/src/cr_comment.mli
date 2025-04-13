(*_*******************************************************************************)
(*_  crs - A tool to manipulate code review comments embedded in source code     *)
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
  * - Remove the [Stable] module - unversion the code.
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
  * - Remove special type for cr soons. Return all CRs parsed.
  * - Rename [Processed] to [Header].
  * - Remove support for printing crs without their content.
  * - Compute positions and offsets with [Loc].
*)

module Kind : sig
  type t =
    | CR
    | XCR
  [@@deriving compare, equal, sexp_of]
end

module Due : sig
  type t =
    | Now
    | Soon
    | Someday
  [@@deriving compare, equal, sexp_of]
end

module Digest_hex : sig
  type t [@@deriving compare, equal, sexp_of]

  val to_string : t -> string
  val create : string -> t
end

module Header : sig
  type t [@@deriving equal, sexp_of]

  (** [reported_by] is [user] in [CR user...]. *)
  val reported_by : t -> Vcs.User_handle.t

  (** [for_] is [user2] in [CR user1 for user2: ...]. It is none since the part
      with the [for user2] is optional. *)
  val for_ : t -> Vcs.User_handle.t option

  val kind : t -> Kind.t
  val due : t -> Due.t
end

type t [@@deriving equal, sexp_of]

(** {1 Getters} *)

val path : t -> Vcs.Path_in_repo.t

(** [content] is the text of the CR with comment markers removed from the
    beginning and end (if applicable). *)
val content : t -> string

(** [whole_loc] is suitable for removal of the entire CR comment. It includes
    the comments boundaries from [path] as well. *)
val whole_loc : t -> Loc.t

val header : t -> Header.t Or_error.t
val kind : t -> Kind.t
val due : t -> Due.t
val work_on : t -> Due.t

(** This digest is computed such that changes in positions in a file, or changes
    in whitespaces are ignored. It is used by downstream systems to detect
    that two crs are equivalent, which in turn may affect when a cr is
    active. *)
val digest_ignoring_minor_text_changes : t -> Digest_hex.t

(** {1 Print} *)

val to_string : t -> string

(** Sorts and prints a list of crs, visually separated if needed. *)
val print_list : crs:t list -> unit

(** {1 Sort} *)

module For_sorted_output : sig
  type nonrec t = t [@@deriving compare]
end

val sort : t list -> t list

(** {1 Private}

    This module is exported to be used by libraries with strong ties to
    [cr_comment]. Its signature may change in breaking ways at any time without
    prior notice, and outside of the guidelines set by semver.

    In particular, the intention here is that cr comments may only be created
    using dedicated helpers libraries that are defined in this project, parsing
    comments from files in vcs trees. *)

module Private : sig
  type header := Header.t

  module Header : sig
    val create
      :  reported_by:Vcs.User_handle.t
      -> for_:Vcs.User_handle.t option
      -> kind:Kind.t
      -> due:Due.t
      -> header
  end

  val create
    :  path:Vcs.Path_in_repo.t
    -> content:string
    -> whole_loc:Loc.t
    -> header:header Or_error.t
    -> digest_of_condensed_content:Digest_hex.t
    -> t
end
