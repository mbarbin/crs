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

(** In the tests we want to avoid test CRs to be mistaken for actual CRs, thus
    we perform some dynamic string substitutions. Test CRs are prefixed by the
    '$' symbol. For example:

    {[
      (* $CR user1 for user2: This is a test CR. *)
    ]}

    [parse_file ~path ~file_contents] first removes the '$' prefixes, and then
    parse the contents using the regular code path to extract CRs from file.

    The provided [path] is not accessed on disk, we simply use it to build
    locations for the resulting CRs. The contents is solely read from
    [file_contents]. *)
val parse_file : path:Vcs.Path_in_repo.t -> file_contents:string -> Cr_comment.t list

(** A shared list of common cases for CRs. This is used by several tests as a
    basis for making sure to handle various kinds of CRs. *)
val test_cases : string
