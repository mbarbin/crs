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

module Summary_table = Crs_cli.Private.Summary_table

let path = Vcs.Path_in_repo.v "my_file.ml"

let%expect_test "empty table" =
  match Summary_table.make [] |> Summary_table.to_print_table with
  | None -> ()
  | Some _ -> assert false
;;

(* We already have a comprehensive test to monitor the various rendering
   implementation of tables in [test__print_table_experimental.ml]. Here we only
   monitor the one that are used by the [crs] cli and actively in use by the
   project. *)

let%expect_test "to_string" =
  let crs = Tests_helpers.parse_file ~path ~file_contents:Tests_helpers.test_cases in
  let table = Summary_table.make crs in
  let print_table = Summary_table.to_print_table table |> Option.get in
  (* Ansi *)
  print_endline (Print_table.to_string_text print_table);
  [%expect
    {|
    ┌──────────┬───────┬─────┬──────┬──────┬─────────┬───────┐
    │ Reporter │ For   │ CRs │ XCRs │ Soon │ Someday │ Total │
    ├──────────┼───────┼─────┼──────┼──────┼─────────┼───────┤
    │ user     │       │   1 │    3 │    1 │       1 │     6 │
    │ user     │ user2 │   1 │    1 │      │         │     2 │
    └──────────┴───────┴─────┴──────┴──────┴─────────┴───────┘
    |}];
  (* GitHub Markdown *)
  print_endline (Print_table.to_string_markdown print_table);
  [%expect
    {|
    | Reporter | For   | CRs | XCRs | Soon | Someday | Total |
    |:---------|:------|----:|-----:|-----:|--------:|------:|
    | user     |       |   1 |    3 |    1 |       1 |     6 |
    | user     | user2 |   1 |    1 |      |         |     2 |
    |}];
  ()
;;
