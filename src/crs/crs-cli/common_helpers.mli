(*_********************************************************************************)
(*_  crs - A tool for managing inline review comments embedded in source code     *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*_********************************************************************************)

(** For use in the rest of the files in this directory. *)

(** Find enclosing repo or raise an error compatible with the command handler in
    use. *)
val find_enclosing_repo : from:Absolute_path.t -> Enclosing_repo.t

(** When supplying path arguments that are aimed to designate paths in repo,
    we need to resolve them according to where the [repo_root] is in relation
    to the cwd. We interpret relative paths as relative to the cwd from which
    the program started. *)
val relativize
  :  repo_root:Vcs.Repo_root.t
  -> cwd:Absolute_path.t
  -> path:Fpath.t
  -> Vcs.Path_in_repo.t

(** Allows to use flags to supply CR filters. For example: [--xcrs] or [--now].
    If no filter flags are supplied, this returns [`All]. *)
val filters : [ `All | `Only of Cr_comment.Filter.t list ] Command.Arg.t

val with_user_mentions_arg : bool Command.Arg.t

(** A shared flag for commands that can emit errors and warnings using special
    annotations when run from within GitHub Actions. *)
val emit_github_annotations_arg : default:bool -> bool Command.Arg.t
