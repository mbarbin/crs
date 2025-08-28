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

(** A helper module to create user messages that may be highlighted by GitHub
    Annotations for accrued discoverability.

    For use in GitHub workflows. *)

(** Emit a warning with [Err.warning] with the supplied messages. For
    convenience and help users discover warnings during CI runs, this can
    optionally include CI warnings on stderr for GitHub, using workflow
    annotations. To activate, supply [emit_github_annotations:true].

    {b Motivation:} When running in CI/CD environments, warnings printed to stderr
    can easily be missed among other output. GitHub workflow annotations provide
    a way to surface these warnings prominently in the GitHub UI, appearing both
    in the workflow run summary and as inline annotations in pull requests. This
    significantly improves the discoverability of warnings that might otherwise
    go unnoticed, helping developers address issues before merging code.

    The optional [hints] parameter provides additional context or suggestions
    for resolving the warning. When GitHub annotations are enabled, hints are
    included in the annotation message with a "Hints: " prefix. *)
val warning
  :  ?loc:Loc.t
  -> emit_github_annotations:bool
  -> ?hints:Pp_tty.t list
  -> Pp_tty.t list
  -> unit
