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

(** A type to hold declarative values to configure crs commands for a given
    repository.

    The expectations is that certain commands allow for a file to be given as
    argument to a [--config FILE] flag, which must contain a serialization of a
    value of type [t].

    This particular config is expected to contain repository specific
    configuration.

    We are using JSON5 as serialization format. *)

module Annotation_severity : sig
  type t =
    | Error
    | Warning
    | Info
  [@@deriving sexp_of]
end

type t [@@deriving sexp_of]

(** {1 Getters} *)

(** [default_repo_owner] When not in a PR, the default_repo_owner may be used to
    assigned certain kinds of otherwise not easy to assign to a particular user.
    For example, invalid CRs when creating CRs annotation for a particular
    commit outside of a pull request.

    If the repository is owned by an individual, this would typically be that
    user. If the repository is owned by an organization, this may be set to a
    user in particular who would be assigned otherwise unassignable CRs. If it
    isn't set, such CRs will simply not be assigned to any one in particular. *)
val default_repo_owner : t -> Vcs.User_handle.t option

(** [user_mentions_allowlist] enables a specific list of users to be notified in
    annotations comments, when notifications is requested. This is a protection
    measure to avoid spamming users that do not have ties to a repo in
    particular, or simply do not wish to be notified via CRs. *)
val user_mentions_allowlist : t -> Vcs.User_handle.t list option

val invalid_crs_annotation_severity : t -> Annotation_severity.t option
val crs_due_now_annotation_severity : t -> Annotation_severity.t option

(** {1 Create configs} *)

val create
  :  ?default_repo_owner:Vcs.User_handle.t
  -> ?user_mentions_allowlist:Vcs.User_handle.t list
  -> ?invalid_crs_annotation_severity:Annotation_severity.t
  -> ?crs_due_now_annotation_severity:Annotation_severity.t
  -> unit
  -> t

val empty : t
val load_exn : path:Fpath.t -> t
