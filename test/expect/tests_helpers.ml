(********************************************************************************)
(*  crs - A tool for managing code review comments embedded in source code      *)
(*  Copyright (C) 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>           *)
(*                                                                              *)
(*  This file is part of crs.                                                   *)
(*                                                                              *)
(*  crs is free software; you can redistribute it and/or modify it under the    *)
(*  terms of the GNU Lesser General Public License as published by the Free     *)
(*  Software Foundation either version 3 of the License, or any later version,  *)
(*  with the LGPL-3.0 Linking Exception.                                        *)
(*                                                                              *)
(*  crs is distributed in the hope that it will be useful, but WITHOUT ANY      *)
(*  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS   *)
(*  FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License and     *)
(*  the file `NOTICE.md` at the root of this repository for more details.       *)
(*                                                                              *)
(*  You should have received a copy of the GNU Lesser General Public License    *)
(*  and the LGPL-3.0 Linking Exception along with this library. If not, see     *)
(*  <http://www.gnu.org/licenses/> and <https://spdx.org>, respectively.        *)
(********************************************************************************)

module String = Base.String

let test ~path ~file_contents:original_contents ~f =
  let file_contents =
    (* In this test we want to avoid test CRs to be mistaken for actual CRs,
       thus we perform some dynamic string substitutions. *)
    original_contents
    |> String.substr_replace_all ~pattern:"$CR" ~with_:"CR"
    |> String.substr_replace_all ~pattern:"$XCR" ~with_:"XCR"
    |> Vcs.File_contents.create
  in
  let crs = Crs_parser.parse_file ~path ~file_contents in
  let file_rewriter =
    File_rewriter.create
      ~path:(Vcs.Path_in_repo.to_fpath path)
      ~original_contents:(file_contents :> string)
  in
  f ~crs ~file_rewriter;
  let output =
    File_rewriter.contents file_rewriter
    |> String.substr_replace_all ~pattern:" CR" ~with_:" $CR"
    |> String.substr_replace_all ~pattern:" XCR" ~with_:" $XCR"
  in
  Expect_test_patdiff.print_patdiff original_contents output ~context:3
;;
