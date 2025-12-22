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
module Summary_table = Crs_cli.Private.Summary_table

let path = Vcs.Path_in_repo.v "my_file.ml"

let test_cases =
  {|
(* $CR user: Hello. *)
(* $CR user for user2: Hello. *)
(* $XCR user for user2: Hello. *)
(* $CR-user: Invalid. *)
(* $CR-soon user: Hello. *)
(* $CR-someday user: Hello. *)
|}
;;

let parse_file ~path ~file_contents =
  let file_contents =
    file_contents
    |> String.strip
    |> String.substr_replace_all ~pattern:"$CR" ~with_:"CR"
    |> String.substr_replace_all ~pattern:"$XCR" ~with_:"XCR"
    |> Vcs.File_contents.create
  in
  Crs_parser.parse_file ~path ~file_contents |> Cr_comment.sort
;;

(* Here we monitor a few rendering options for text tables as a reference, to
   help visualize and experiment with which makes the most sense to use for this
   project depending on the context. *)

let%expect_test "to_string" =
  let crs = parse_file ~path ~file_contents:test_cases in
  let table = Summary_table.make crs in
  let print_table = Summary_table.to_print_table table |> Option.value_exn in
  (* Ansi *)
  print_endline (Print_table.to_string_text print_table);
  [%expect
    {|
    ┌──────────┬───────┬─────┬──────┬──────┬─────────┬───────┐
    │ Reporter │ For   │ CRs │ XCRs │ Soon │ Someday │ Total │
    ├──────────┼───────┼─────┼──────┼──────┼─────────┼───────┤
    │ user     │       │   1 │      │    1 │       1 │     3 │
    │ user     │ user2 │   1 │    1 │      │         │     2 │
    └──────────┴───────┴─────┴──────┴──────┴─────────┴───────┘
    |}];
  (* GitHub Markdown *)
  print_endline (Print_table.to_string_markdown print_table);
  [%expect
    {|
    | Reporter | For   | CRs | XCRs | Soon | Someday | Total |
    |:---------|:------|----:|-----:|-----:|--------:|------:|
    | user     |       |   1 |      |    1 |       1 |     3 |
    | user     | user2 |   1 |    1 |      |         |     2 |
    |}];
  (* Ansi via Printbox. *)
  let printbox = Printbox_table.of_print_table print_table in
  print_endline (PrintBox_text.to_string printbox ^ "\n");
  [%expect
    {|
    ┌──────────┬───────┬─────┬──────┬──────┬─────────┬───────┐
    │ Reporter │ For   │ CRs │ XCRs │ Soon │ Someday │ Total │
    ├──────────┼───────┼─────┼──────┼──────┼─────────┼───────┤
    │ user     │       │   1 │      │    1 │       1 │     3 │
    │ user     │ user2 │   1 │    1 │      │         │     2 │
    └──────────┴───────┴─────┴──────┴──────┴─────────┴───────┘
    |}];
  (* GitHub Markdown via Printbox. *)
  print_endline (Printbox_table.to_string_markdown printbox);
  [%expect
    {|
    |----------|-------|-----|------|------|---------|-------|
    | Reporter | For   | CRs | XCRs | Soon | Someday | Total |
    |----------|-------|-----|------|------|---------|-------|
    | user     |       |   1 |      |    1 |       1 |     3 |
    | user     | user2 |   1 |    1 |      |         |     2 |
    |----------|-------|-----|------|------|---------|-------|
    |}];
  let with_md_config ~config =
    let md = PrintBox_md.to_string config printbox in
    print_endline (String.strip md ^ "\n")
  in
  (* Markdown via Printbox - default config. *)
  with_md_config ~config:PrintBox_md.Config.default;
  [%expect
    {|
    >
    > ```
    >  Reporter │ For   │ CRs │ XCRs │ Soon │ Someday │ Total
    > ──────────┼───────┼─────┼──────┼──────┼─────────┼───────
    >  user     │       │   1 │      │    1 │       1 │     3
    >  user     │ user2 │   1 │    1 │      │         │     2
    > ```
    >
    >
    >
    |}];
  (* Markdown via Printbox - uniform config. *)
  with_md_config ~config:PrintBox_md.Config.uniform;
  [%expect
    {|
    ```
    ┌──────────┬───────┬─────┬──────┬──────┬─────────┬───────┐
    │ Reporter │ For   │ CRs │ XCRs │ Soon │ Someday │ Total │
    ├──────────┼───────┼─────┼──────┼──────┼─────────┼───────┤
    │ user     │       │   1 │      │    1 │       1 │     3 │
    │ user     │ user2 │   1 │    1 │      │         │     2 │
    └──────────┴───────┴─────┴──────┴──────┴─────────┴───────┘
    ```
    |}];
  ()
;;

let%expect_test "empty columns" =
  let crs = parse_file ~path ~file_contents:"(* $CR-soon user: Hello CR! *)" in
  let table = Summary_table.make crs in
  let print_table = Summary_table.to_print_table table |> Option.value_exn in
  let printbox = Printbox_table.of_print_table print_table in
  print_endline (PrintBox_text.to_string printbox ^ "\n");
  [%expect
    {|
    ┌──────────┬──────┬───────┐
    │ Reporter │ Soon │ Total │
    ├──────────┼──────┼───────┤
    │ user     │    1 │     1 │
    └──────────┴──────┴───────┘
    |}]
;;

(* This test was copied from the print-table test suite in order to fully cover
   the use of styles in the experimental print-table -> printbox translation. *)
(****************************************************************************)
(*  print-table - Simple Unicode/ANSI and Markdown text table rendering     *)
(*  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: ISC                                            *)
(****************************************************************************)
let%expect_test "style" =
  let columns =
    Print_table.O.
      [ Column.make ~header:"Name" (fun (name, _) -> Cell.text name)
      ; Column.make ~header:"Style" ~align:Center (fun (_, style) -> Cell.text ~style "v")
      ]
  in
  let print_table =
    Print_table.make
      ~columns
      ~rows:
        Print_table.O.
          [ "default", Style.default
          ; "fg_green", Style.fg_green
          ; "fg_rd", Style.fg_red
          ; "fg_yellow", Style.fg_yellow
          ; "dim", Style.dim
          ; "underscore", Style.underscore
          ]
  in
  (* Ansi via Printbox. *)
  let printbox = Printbox_table.of_print_table print_table in
  print_endline (PrintBox_text.to_string printbox ^ "\n");
  [%expect
    {|
    ┌────────────┬───────┐
    │ Name       │ Style │
    ├────────────┼───────┤
    │ default    │   v   │
    │ fg_green   │   [32mv[0m   │
    │ fg_rd      │   [31mv[0m   │
    │ fg_yellow  │   [33mv[0m   │
    │ dim        │   v   │
    │ underscore │   v   │
    └────────────┴───────┘
    |}];
  ()
;;
