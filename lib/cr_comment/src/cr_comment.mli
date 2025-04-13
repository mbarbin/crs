(*_*******************************************************************************)
(*_  crs - A tool to parse code review comments embedded in source code          *)
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

(*_ This module is derived from Iron (v0.9.114.44+47), file
  * [./hg/cr_comment.mli], which is released under Apache 2.0:
  *
  * Copyright (c) 2016-2017 Jane Street Group, LLC <opensource-contacts@janestreet.com>
  *
  * Licensed under the Apache License, Version 2.0 (the "License"); you may not
  * use this file except in compliance with the License. You may obtain a copy
  * of the License at:
  *
  *     http://www.apache.org/licenses/LICENSE-2.0
  *
  * Unless required by applicable law or agreed to in writing, software
  * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
  * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
  * License for the specific language governing permissions and limitations
  * under the License.
  *
  * See the file `NOTICE.md` at the root of this repository for more details.
  *
  * Changes: ...
  *
  * - Remove dependency to [Core] and [Async].
  * - Remove the [Stable] module - unversion the code.
  * - Replace [Relpath] by [Vcs.Path_in_repo].
  * - Remove [of_sexp] constructs.
  * - Remove [Cr_comment_format].
  * - Replace [Unresolved_name] by [Vcs.User_handle].
  * - Remove [deriving fields] ppx constructs.
  * - Remove alternate names and aliases resolution.
  * - Remove incremental computation features.
  * - Remove summary tables.
  * - Remove invariant checks.
  * - Use [Vcs] instead of [Hg].
  * - Remove [Crs_due_now_and_soon].
  * - Remove support for extra headers.
  * - Remove support for attributes.
  * - Remove assignee computation (left as external work).
  * - Do not export [Raw].
  * - Remove special type for cr soons. Return all CRs parsed.
*)

module Kind : sig
  type t =
    | CR
    | XCR
  [@@deriving compare, equal, sexp_of]
end

module Due : sig
  type t =
    | Now
    | Soon
    | Someday
  [@@deriving compare, equal, sexp_of]
end

type t [@@deriving sexp_of]

val hash : t -> int
val path : t -> Vcs.Path_in_repo.t
val content : t -> string
val start_line : t -> int
val start_col : t -> int
val due : t -> Due.t
val is_xcr : t -> bool
val work_on : t -> Due.t
val to_string : t -> include_content:bool -> string

(** Sorts and prints a list of crs separated by whitespace (if needed). *)
val print_list : crs:t list -> include_content:bool -> unit

module Structurally_compared : sig
  type nonrec t = t [@@deriving compare, sexp_of]
end

module For_sorted_output : sig
  type nonrec t = t [@@deriving compare]
end

val sort : t list -> t list

val grep
  :  vcs:[> Vcs.Trait.ls_files ] Vcs.t
  -> repo_root:Vcs.Repo_root.t
  -> below:Vcs.Path_in_repo.t
  -> t list
