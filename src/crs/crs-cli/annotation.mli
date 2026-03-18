(*_********************************************************************************)
(*_  crs - A tool for managing inline review comments embedded in source code     *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*_********************************************************************************)

(** A type to hold information about a CR that is assigned in the ci event (pull
    request or push to ongoing branch).

    This is used by workflow that integrate with platforms or tools supporting
    annotations, such as GitHub Annotations, and Reviewdog Diagnostics. *)

module Severity : sig
  type t = Config.Annotation_severity.t =
    | Error
    | Warning
    | Info

  val all : t list
  val to_dyn : t -> Dyn.t

  (** Capitalized like the constructor (e.g. ["Error"]). *)
  val to_string : t -> string

  val to_github : t -> Github_annotation.Severity.t
  val to_reviewdog : t -> Reviewdog.Severity.t
end

type t

val to_dyn : t -> Dyn.t

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
val write_username : user:User_handle.t -> with_user_mention:bool -> string

(** {1 Getters} *)

val message : t -> string
val severity : t -> Severity.t
val assignee : t -> Assignee.t
val with_user_mention : t -> bool

(** Export to supported consumers / backend. *)

val to_github_annotation : t -> Github_annotation.t
val to_reviewdog_diagnostic : t -> Reviewdog.Diagnostic.t
