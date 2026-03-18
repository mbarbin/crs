(*_********************************************************************************)
(*_  crs - A tool for managing inline review comments embedded in source code     *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*_********************************************************************************)

(** [Review_mode.t] describes the context in which the CR assignment and
    annotation logic is executed. This is not strictly tied to the CI event that
    triggered the workflow, but rather to the review/assignment semantics:

    - [Pull_request]: The workflow is running in the context of a pull request,
      and the [author] is the user who opened the PR. We are in the process of
      requiring the [base] revision of the PR, but currently are supporting older
      workflow that do not supply it. We expect the base to be supplied by the
      most up to date clients.

    - [Revision]: The workflow is running in the vcs tree checked out at a
      specific revision and there is no specific PR.

    There exists a natural mapping between the event kinds that are triggering
    GitHub Actions Workflows and this review mode. Namely:

    - [github.event_name == 'pull_request']: This is a pull request event and
      maps to the [Pull_request] review mode.

    - [github.event_name == 'push']: Jobs triggered on a ['push'] event are best
      run in [Revision] review mode. In this mode, workflows run in the tree
      checked out at a specific revision, but the context is not tied to a
      particular pull request. *)

type t =
  | Pull_request of
      { author : User_handle.t
      ; base : Vcs.Rev.t option
      }
  | Revision

val equal : t -> t -> bool
val to_dyn : t -> Dyn.t

(** Build a [t] from parsing arguments in the command line. For convenience and
    help users discover warnings during CI runs, this can optionally include CI
    warnings on stderr for GitHub, using workflow annotations. To activate, supply
    [emit_github_annotations:true]. *)
val arg : emit_github_annotations:bool -> t Command.Arg.t
