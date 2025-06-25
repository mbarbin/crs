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
[@@deriving compare, equal, enumerate, sexp_of]

(** This returns the planned time to work on the CR according to the qualifier. *)
val due : t -> Due.t
