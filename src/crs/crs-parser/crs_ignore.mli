(*_*******************************************************************************)
(*_  crs - A tool for managing inline review comments embedded in source code    *)
(*_  Copyright (C) 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>           *)
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

(** A [.crs-ignore] file allows listing files and directories that should be
    ignored when looking for CRs in the tree.

    The primary motivation for this is to help managing files that document the
    CRs system itself. In these files, we often end up with CRs featured as
    examples. We don't want to conflate them with actual CRs.

    Each line specifies a pattern to ignore, relative to the directory where the
    ignore file is located. in that directory. The format supports:

    {v
      # Lines starting with '#' are comments.
      # Blank lines are ignored.

      # Match specific files by basename
      README.md
      test.ml

      # Shell-style patterns are supported
      *.tmp
      test_*.ml

      # Directories can be ignored (affects all contents recursively)
      _build/**
      node_modules/**
    v} *)

(** The canonical name expected for this files is [".crs-ignore"]. *)
val filename : Fsegment.t

module File : sig
  type t

  (** Loads a [.crs-ignore] file from the supplied path. *)
  val load_exn
    :  repo_root:Vcs.Repo_root.t
    -> path:Vcs.Path_in_repo.t
    -> invalid_patterns_are_errors:bool
    -> emit_github_annotations:bool
    -> t
end

module Rules : sig
  (** This module allows to implement some caching or any other useful utils
      when dealing with all the [.crs-ignore] files from the tree at once. *)

  type t

  (** After having loaded all [".crs-ignore"] files from the repo, you can build
      a [t] value from there aggregation. The expectation is that they should
      all come from the same [repo_root] or the behavior is unspecified. *)
  val create : File.t list -> t

  (** This will go from the deeper directory containing the path, and then
      walking up, until a pattern is found that instruct that this file would be
      ignored. If no pattern was encountered upon reaching the root of the
      repository, this returns [false]. *)
  val is_file_ignored : t -> path:Vcs.Path_in_repo.t -> bool

  (** After having performed [is_file_ignored] operations, it is possible to use
      this function to access all located patterns that haven't been used. This
      is used by a validation command, to trigger some warning inviting the user
      to clean their crs-ignore config files. *)
  val unused_patterns : t -> string Loc.Txt.t list
end

module Private : sig
  module File : sig
    val parse_exn
      :  repo_root:Vcs.Repo_root.t
      -> path:Vcs.Path_in_repo.t
      -> file_contents:Vcs.File_contents.t
      -> invalid_patterns_are_errors:bool
      -> emit_github_annotations:bool
      -> File.t
  end
end
