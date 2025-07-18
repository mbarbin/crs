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

let%expect_test "no columns!" =
  let text_table = Text_table.make ~columns:[] ~rows:[] in
  (* Ansi *)
  print_endline (Text_table.to_string_ansi text_table);
  [%expect {||}];
  (* GitHub Markdown *)
  print_endline (Text_table.to_string_markdown text_table);
  [%expect {||}];
  (* Ansi via Printbox. *)
  let printbox = Printbox_table.of_text_table text_table in
  print_endline (PrintBox_text.to_string printbox ^ "\n");
  [%expect
    {|
    ┬
    ┴
    |}];
  (* GitHub Markdown via Printbox. *)
  print_endline (Printbox_table.to_string_markdown printbox);
  [%expect
    {|
    |
    |
    |}];
  let with_md_config ~config =
    let md = PrintBox_md.to_string config printbox in
    print_endline (String.strip md ^ "\n")
  in
  (* Markdown via Printbox - default config. *)
  with_md_config ~config:PrintBox_md.Config.default;
  [%expect {| > |}];
  (* Markdown via Printbox - uniform config. *)
  with_md_config ~config:PrintBox_md.Config.uniform;
  [%expect
    {|
    ```
    ┬
    ┴
    ```
    |}];
  ()
;;

let%expect_test "style" =
  let columns =
    Text_table.O.
      [ Column.make ~header:"Name" (fun (name, _) -> Cell.text name)
      ; Column.make ~header:"Style" (fun (_, style) -> Cell.text ~style "v")
      ]
  in
  let print_table =
    Text_table.make
      ~columns
      ~rows:
        Text_table.O.
          [ "default", Style.default
          ; "fg_green", Style.fg_green
          ; "fg_rd", Style.fg_red
          ; "fg_yellow", Style.fg_yellow
          ]
  in
  print_endline (Text_table.to_string_ansi print_table);
  [%expect
    {|
    ┌───────────┬───────┐
    │ Name      │ Style │
    ├───────────┼───────┤
    │ default   │ v     │
    │ fg_green  │ [32mv    [0m │
    │ fg_rd     │ [31mv    [0m │
    │ fg_yellow │ [33mv    [0m │
    └───────────┴───────┘
    |}];
  (* GitHub Markdown. *)
  print_endline (Text_table.to_string_markdown print_table);
  [%expect
    {|
    | Name      | Style |
    |:----------|:------|
    | default   | v     |
    | fg_green  | v     |
    | fg_rd     | v     |
    | fg_yellow | v     |
    |}];
  (* Ansi via Printbox. *)
  let printbox = Printbox_table.of_text_table print_table in
  print_endline (PrintBox_text.to_string printbox ^ "\n");
  [%expect
    {|
    ┌───────────┬───────┐
    │ Name      │ Style │
    ├───────────┼───────┤
    │ default   │ v     │
    │ fg_green  │ [32mv[0m     │
    │ fg_rd     │ [31mv[0m     │
    │ fg_yellow │ [33mv[0m     │
    └───────────┴───────┘
    |}];
  ()
;;

let%expect_test "cell" =
  let cell = Text_table.Cell.empty in
  require [%here] (Text_table.Cell.is_empty cell);
  [%expect {||}];
  let cell = Text_table.Cell.text "" in
  require [%here] (Text_table.Cell.is_empty cell);
  [%expect {||}];
  let cell = Text_table.Cell.text "not empty!" in
  require [%here] (not (Text_table.Cell.is_empty cell));
  [%expect {||}];
  ()
;;

let%expect_test "text_table" =
  let columns =
    Text_table.O.
      [ Column.make ~header:"Name" (fun (name, _) -> Cell.text name)
      ; Column.make ~header:"Empty" (fun (_, _) -> Cell.empty)
      ; Column.make ~header:"Score" ~align:Right (fun (_, score) ->
          Cell.text
            ~style:(if score < 10 then Style.fg_red else Style.default)
            (Int.to_string_hum score))
      ; Column.make ~header:"Stars" ~align:Center (fun (_, score) ->
          Cell.text (if score > 40 then "***" else if score > 10 then "*" else ""))
      ]
  in
  (* Test empty tables. *)
  let rows = [] in
  let text_table = Text_table.make ~columns ~rows in
  (* Ansi *)
  print_endline (Text_table.to_string_ansi text_table);
  [%expect {||}];
  (* GitHub Markdown *)
  print_endline (Text_table.to_string_markdown text_table);
  [%expect {||}];
  (* Ansi via Printbox. *)
  let printbox = Printbox_table.of_text_table text_table in
  print_endline (PrintBox_text.to_string printbox ^ "\n");
  [%expect
    {|
    ┬
    ┴
    |}];
  (* GitHub Markdown via Printbox. *)
  print_endline (Printbox_table.to_string_markdown printbox);
  [%expect
    {|
    |
    |
    |}];
  let with_md_config ~config =
    let md = PrintBox_md.to_string config printbox in
    print_endline (String.strip md ^ "\n")
  in
  (* Markdown via Printbox - default config. *)
  with_md_config ~config:PrintBox_md.Config.default;
  [%expect {| > |}];
  (* Markdown via Printbox - uniform config. *)
  with_md_config ~config:PrintBox_md.Config.uniform;
  [%expect
    {|
    ```
    ┬
    ┴
    ```
    |}];
  (* Not empty. *)
  let rows = [ "Alice", 42; "Bob", 7; "Eve", 13 ] in
  let text_table = Text_table.make ~columns ~rows in
  (* Ansi *)
  print_endline (Text_table.to_string_ansi text_table);
  [%expect
    {|
    ┌───────┬───────┬───────┐
    │ Name  │ Score │ Stars │
    ├───────┼───────┼───────┤
    │ Alice │    42 │  ***  │
    │ Bob   │ [31m    7[0m │       │
    │ Eve   │    13 │   *   │
    └───────┴───────┴───────┘
    |}];
  (* GitHub Markdown *)
  print_endline (Text_table.to_string_markdown text_table);
  [%expect
    {|
    | Name  | Score | Stars |
    |:------|------:|:-----:|
    | Alice |    42 |  ***  |
    | Bob   |     7 |       |
    | Eve   |    13 |   *   |
    |}];
  (* Ansi via Printbox. *)
  let printbox = Printbox_table.of_text_table text_table in
  print_endline (PrintBox_text.to_string printbox ^ "\n");
  [%expect
    {|
    ┌───────┬───────┬───────┐
    │ Name  │ Score │ Stars │
    ├───────┼───────┼───────┤
    │ Alice │    42 │  ***  │
    │ Bob   │     [31m7[0m │       │
    │ Eve   │    13 │   *   │
    └───────┴───────┴───────┘
    |}];
  (* GitHub Markdown via Printbox. *)
  print_endline (Printbox_table.to_string_markdown printbox);
  [%expect
    {|
    |-------|-------|-------|
    | Name  | Score | Stars |
    |-------|-------|-------|
    | Alice |    42 |  ***  |
    | Bob   |     [31m7[0m |       |
    | Eve   |    13 |   *   |
    |-------|-------|-------|
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
    >  Name  │ Score │ Stars
    > ───────┼───────┼───────
    >  Alice │    42 │  ***
    >  Bob   │     7 │
    >  Eve   │    13 │   *
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
    ┌───────┬───────┬───────┐
    │ Name  │ Score │ Stars │
    ├───────┼───────┼───────┤
    │ Alice │    42 │  ***  │
    │ Bob   │     7 │       │
    │ Eve   │    13 │   *   │
    └───────┴───────┴───────┘
    ```
    |}];
  ()
;;
