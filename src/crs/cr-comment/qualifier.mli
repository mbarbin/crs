(*_********************************************************************************)
(*_  crs - A tool for managing inline review comments embedded in source code     *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*_********************************************************************************)

(** The [Qualifier.t] type represents an optional keyword that can be attached
    to a code review comment (CR) using the CR syntax. This classification is a
    general convenience provided by the library to help organize and filter CRs,
    but the exact workflow and expectations associated with each qualifier —
    such as when a [Soon] or [Someday] comment should be addressed — are
    intentionally left undefined here.

    It is up to higher-level tools or code review systems built on top of CRs to
    define and enforce specific policies or behaviors around these qualifiers.

    As a rule of thumb:
    - [None]: Should be addressed promptly.
    - [Soon]: Should be addressed in the near future.
    - [Someday]: Can be deferred until later.

    These categories are intended to be flexible and adaptable to the needs of
    various development process. *)
type t =
  | None
  | Soon
  | Someday

val compare : t -> t -> int
val equal : t -> t -> bool
val all : t list
val to_dyn : t -> Dyn.t

(** This returns the priority according to the qualifier, if we were to take
    nothing else into account. *)
val priority : t -> Priority.t
