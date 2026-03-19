(*_********************************************************************************)
(*_  crs - A tool for managing inline review comments embedded in source code     *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*_********************************************************************************)

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
