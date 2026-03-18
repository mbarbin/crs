(*_********************************************************************************)
(*_  crs - A tool for managing inline review comments embedded in source code     *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*_********************************************************************************)

module Reason : sig
  type t =
    | Not_due_now
    | Recipient
    | Reporter
    | Default_repo_owner
    | No_default_repo_owner
    | Pull_request_author

  val all : t list
  val to_dyn : t -> Dyn.t
  val to_string_hum : t -> string
end

type t =
  { user : User_handle.t option
  ; reason : Reason.t
  }

val to_dyn : t -> Dyn.t
val compute : cr:Cr_comment.t -> config:Config.t -> review_mode:Review_mode.t -> t
