(*_********************************************************************************)
(*_  crs - A tool for managing inline review comments embedded in source code     *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*_********************************************************************************)

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
