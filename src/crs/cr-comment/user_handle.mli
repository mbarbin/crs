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

(** A user handle as it appears in CR comments and related metadata (such as
    pull request author).

    This type is more permissive than a git username [Vcs.User_handle.t], in
    order to capture certain usages across platforms such as GitHub, GitLab,
    etc. For example, square brackets are allowed to accommodate bot account
    names on GitHub (e.g., [dependabot[bot]] as PRs author).

    The supported character set is:
    - alphanumeric characters
    - [-] (hyphen)
    - [_] (underscore)
    - [.] (dot)
    - [\[] and [\]] (square brackets) *)

type t

val compare : t -> t -> int
val equal : t -> t -> bool
val to_string : t -> string
val to_dyn : t -> Dyn.t
val to_json : t -> Json.t
val of_json : Json.t -> t

(** [of_string str] returns [Ok str] if the string is a valid user handle, and
    an error otherwise. This is meant to be used to validate untrusted entries. *)
val of_string : string -> (t, [ `Msg of string ]) Result.t

(** [v str] is a convenient wrapper to build a [t] or raise [Invalid_argument].
    This is typically handy for applying on trusted literals. *)
val v : string -> t
