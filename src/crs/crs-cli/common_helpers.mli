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
