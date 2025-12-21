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
  val sexp_of_t : t -> Sexp.t
  val to_string_hum : t -> string
end

type t =
  { user : Vcs.User_handle.t option
  ; reason : Reason.t
  }

val to_dyn : t -> Dyn.t
val sexp_of_t : t -> Sexp.t
val compute : cr:Cr_comment.t -> config:Config.t -> review_mode:Review_mode.t -> t
