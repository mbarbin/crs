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

type t = Text_table_ast.t

let to_string_non_empty t =
  let buffer = Buffer.create 128 in
  let box = Box.of_text_table t in
  let columns = box.columns in
  let columns_count = Array.length columns in
  (* Header row *)
  Buffer.add_char buffer '|';
  Array.iter columns ~f:(fun col ->
    Buffer.add_char buffer ' ';
    Buffer.add_string buffer (Box.pad col.header ~len:col.length ~align:col.align);
    Buffer.add_char buffer ' ';
    Buffer.add_char buffer '|');
  Buffer.add_char buffer '\n';
  (* Alignment row *)
  Buffer.add_char buffer '|';
  Array.iter columns ~f:(fun col ->
    let spec =
      match col.align with
      | Left -> ":" ^ String.make (col.length + 1) '-'
      | Right -> String.make (col.length + 1) '-' ^ ":"
      | Center -> ":" ^ String.make col.length '-' ^ ":"
    in
    Buffer.add_string buffer spec;
    Buffer.add_char buffer '|');
  Buffer.add_char buffer '\n';
  (* Rows *)
  let n_rows =
    if columns_count = 0
    then assert false [@coverage off]
    else List.length columns.(0).cells
  in
  for i = 0 to n_rows - 1 do
    Buffer.add_char buffer '|';
    Array.iter columns ~f:(fun col ->
      (* [nth_exn] thanks to invariant from Box: all cells have the same length. *)
      let { Text_table_ast.Cell.text; style } = List.nth_exn col.cells i in
      let () =
        match style with
        | Default | Fg_red ->
          (* There is no support for controlling colors in the GitHub Markdown
             syntax. We simply do not render them. *)
          ()
      in
      Buffer.add_char buffer ' ';
      Buffer.add_string buffer (Box.pad text ~len:col.length ~align:col.align);
      Buffer.add_char buffer ' ';
      Buffer.add_char buffer '|');
    Buffer.add_char buffer '\n'
  done;
  Buffer.contents buffer
;;

let to_string (Text_table_ast.T { rows; columns } as t) =
  if List.is_empty columns || List.is_empty rows then "" else to_string_non_empty t
;;
