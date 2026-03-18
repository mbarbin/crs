(*_********************************************************************************)
(*_  crs - A tool for managing inline review comments embedded in source code     *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*_********************************************************************************)

(** The [Priority.t] type represents a priority classification that can be
    associated with a code review comment (CR). Assignment of a priority is
    not always direct; rather, it is typically computed as a function of other
    elements such as the CR's status, review context, and qualifier.

    This classification is intended as a general convenience to help organize
    and filter CRs by indicating the reviewers's intent or suggested importance,
    but it does not prescribe a specific workflow or deadline.

    The meaning and enforcement of each priority class — such as when a [Soon]
    or [Someday] comment should be addressed — are intentionally left undefined
    at this level. Higher-level tools or code review systems built on top of CRs
    may define their own policies or behaviors around these categories.

    In the terminology used in the project, you'll sometimes come across
    language that makes a direct parallel between the CR's priority, and when
    work on it is expected to be "due" or meant to happen.

    Typical interpretations:
    - [Now]: Should be addressed promptly (while working on a PR for example).
    - [Soon]: Should be addressed in the near future.
    - [Someday]: Can be deferred until later.

    These categories are intentionally flexible and meant to support a variety of
    development processes and team conventions. *)
type t =
  | Now
  | Soon
  | Someday

val compare : t -> t -> int
val equal : t -> t -> bool
val all : t list
val to_dyn : t -> Dyn.t
