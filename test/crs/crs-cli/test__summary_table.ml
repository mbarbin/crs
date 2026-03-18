(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

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
