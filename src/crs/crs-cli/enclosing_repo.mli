(*_********************************************************************************)
(*_  crs - A tool for managing inline review comments embedded in source code     *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*_********************************************************************************)

(** This application works from within a Git or Mercurial repository.

    This module specifies which functionality the rest of the application relies
    on, by defining the specific set of traits that are required. We make use of
    the [volgo] library for this. *)

module Vcs_kind : sig
  (** The kind of vcs supported by the cli. *)
  type t =
    [ `Git
    | `Hg
    ]

  val to_string : t -> string
end

(** The specific list of traits that must be implemented by a vcs backend in
    order for it to be used by the cli. *)
type vcs = < Vcs.Trait.file_system ; Vcs.Trait.ls_files > Vcs.t

(** A type to represent the vcs found when walking up from within a directory
    located inside a repo. *)
type t =
  { vcs_kind : Vcs_kind.t
  ; repo_root : Vcs.Repo_root.t
  ; vcs : vcs
  }
