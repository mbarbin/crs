(*_********************************************************************************)
(*_  crs - A tool for managing inline review comments embedded in source code     *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*_********************************************************************************)

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

(** Same as [warning] but with the severity of an error. This results in making
    the overall exit code of the application a non-zero code. *)
val error
  :  ?loc:Loc.t
  -> emit_github_annotations:bool
  -> ?hints:Pp_tty.t list
  -> Pp_tty.t list
  -> unit
