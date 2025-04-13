(*_*******************************************************************************)
(*_  crs - A tool to manipulate code review comments embedded in source code     *)
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
  * - Migrate to this file only the part that relates to parsing files.
  * - Remove dependency to [Core] and [Async].
  * - Remove [Cr_comment_format].
  * - Replace [Unresolved_name] by [Vcs.User_handle].
  * - Remove alternate names and aliases resolution.
  * - Use [Vcs] instead of [Hg].
  * - Remove support for extra headers.
  * - Remove support for attributes.
  * - Remove assignee computation (left as external work).
*)

val cr_pattern_egrep : string

val parse_file
  :  path:Vcs.Path_in_repo.t
  -> file_contents:Vcs.File_contents.t
  -> Cr_comment.t list
