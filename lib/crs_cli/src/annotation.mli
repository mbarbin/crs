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

(** A type to hold information about a CR that is assigned in the ci event (pull
    request or push to ongoing branch).

    This is used by workflow that integrate with platforms or tools supporting
    annotations, such as GitHub Annotations, and Reviewdog Diagnostics. *)

module Severity : sig
  type t = Config.Annotation_severity.t =
    | Error
    | Warning
    | Info
  [@@deriving enumerate, sexp_of]

  (** Capitalized like the constructor (e.g. ["Error"]). *)
  val to_string : t -> string

  val to_github : t -> Github_annotation.Severity.t
  val to_reviewdog : t -> Reviewdog_rdf.severity
end

type t [@@deriving sexp_of]

(** When [with_user_mentions] is true, we prefix user names by '@' in
    annotations messages. See also {!val:write_username}. *)
val of_cr
  :  cr:Cr_comment.t
  -> config:Config.t
  -> review_mode:Review_mode.t
  -> with_user_mentions:bool
  -> t option

(** {1 Utils} *)

(** When [with_user_mention] is [true] we use the syntax '@user' in the
    annotation message to trigger a notification in the environment that will
    end up rendering this string. This doesn't always work, even when this is
    the correct syntax. For example, mentioning a user with '@' in a GitHub
    Annotations Panels does nothing. *)
val write_username : user:Vcs.User_handle.t -> with_user_mention:bool -> string

(** {1 Getters} *)

val message : t -> string
val severity : t -> Severity.t
val assignee : t -> Assignee.t
val with_user_mention : t -> bool

(** Export to supported consumers / backend. *)

val to_github_annotation : t -> Github_annotation.t
val to_reviewdog_diagnostic : t -> Reviewdog_rdf.diagnostic
