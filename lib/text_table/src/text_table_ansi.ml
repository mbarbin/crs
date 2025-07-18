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

let repeat c n = List.init n ~f:(fun _ -> c) |> String.concat

let to_string_non_empty t =
  let box = Box.of_text_table t in
  let buffer = Buffer.create 128 in
  let columns = box.columns in
  let columns_count = Array.length columns in
  let draw_line left sep right fill =
    Buffer.add_string buffer left;
    Array.iteri columns ~f:(fun i col ->
      if i > 0 then Buffer.add_string buffer sep;
      Buffer.add_string buffer (repeat fill (col.length + 2)));
    Buffer.add_string buffer right;
    Buffer.add_char buffer '\n'
  in
  (* Top border *)
  draw_line "┌" "┬" "┐" "─";
  (* Header row *)
  Buffer.add_string buffer "│";
  Array.iter columns ~f:(fun col ->
    Buffer.add_char buffer ' ';
    Buffer.add_string buffer (Box.pad col.header ~len:col.length ~align:col.align);
    Buffer.add_char buffer ' ';
    Buffer.add_string buffer "│");
  Buffer.add_char buffer '\n';
  (* Header separator *)
  draw_line "├" "┼" "┤" "─";
  (* Rows *)
  let num_rows =
    if columns_count = 0
    then assert false [@coverage off]
    else List.length columns.(0).cells
  in
  for i = 0 to num_rows - 1 do
    Buffer.add_string buffer "│";
    Array.iter columns ~f:(fun col ->
      (* [nth_exn] thanks to invariant from Box: all cells have the same length. *)
      let { Text_table_ast.Cell.text; style } = List.nth_exn col.cells i in
      Buffer.add_char buffer ' ';
      let add_colored_text color_code =
        Buffer.add_string buffer color_code;
        Buffer.add_string buffer (Box.pad text ~len:col.length ~align:col.align);
        Buffer.add_string buffer "\027[0m"
      in
      (match style with
       | Default ->
         Buffer.add_string buffer (Box.pad text ~len:col.length ~align:col.align)
       | Fg_red -> add_colored_text "\027[31m"
       | Fg_green -> add_colored_text "\027[32m"
       | Fg_yellow -> add_colored_text "\027[33m");
      Buffer.add_char buffer ' ';
      Buffer.add_string buffer "│");
    Buffer.add_char buffer '\n'
  done;
  (* Bottom border *)
  draw_line "└" "┴" "┘" "─";
  Buffer.contents buffer
;;

let to_string (Text_table_ast.T { rows; columns } as t) =
  if List.is_empty columns || List.is_empty rows then "" else to_string_non_empty t
;;
