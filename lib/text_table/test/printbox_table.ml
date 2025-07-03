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

(* This was mostly an experiment. We ended up implementing a direct rendering
   from [Text_table] to markdown without [PrintBox] intermediary. Keeping for
   experimentations (test dependencies only). *)

type t = PrintBox.t

let of_text_table t =
  let (Text_table.Private.Ast.T { columns; rows }) = Text_table.Private.to_ast t in
  let pad_cell box = PrintBox.hpad 1 box in
  PrintBox.(
    frame
      (hlist
         (List.filter_map columns ~f:(fun { header; align = align_h; make_cell } ->
            let align_h =
              match align_h with
              | Left -> `Left
              | Center -> `Center
              | Right -> `Right
            in
            let cells = List.map rows ~f:make_cell in
            if List.for_all cells ~f:(fun { style = _; text } -> String.is_empty text)
            then None
            else
              Some
                (vlist
                   [ align ~h:align_h ~v:`Center (pad_cell (line header))
                   ; grid_l
                       ~bars:false
                       (List.map cells ~f:(fun { style; text } ->
                          let box =
                            (* When encountering an empty cell, [grid_l] shifts
                               the remaining rows up one level, which creates a
                               misalignment. Thus we use a workaround here. *)
                            match String.is_empty text with
                            | true -> line " "
                            | false ->
                              (match style with
                               | Default -> line text
                               | Fg_red -> line_with_style (Style.fg_color Red) text)
                          in
                          [ align ~h:align_h ~v:`Center (pad_cell box) ]))
                   ])))))
;;

let map_utf8_string s ~f =
  let b = Buffer.create (String.length s) in
  let rec loop d =
    match Uutf.decode d with
    | `End -> ()
    | `Uchar u ->
      Stdlib.Buffer.add_utf_8_uchar b (f u);
      loop d
    | `Malformed _ | `Await -> assert false
  in
  let d = Uutf.decoder (`String s) in
  loop d;
  Buffer.contents b
;;

let to_md_line s =
  map_utf8_string s ~f:(fun u ->
    match Stdlib.Uchar.to_int u with
    | 9472 -> Uchar.of_char '-' (* '─' Horizontal line *)
    | 9474 -> Uchar.of_char '|' (* '│' Vertical line *)
    | 9484 -> Uchar.of_char '|' (* '┌' Top left corner *)
    | 9488 -> Uchar.of_char '|' (* '┐' Top right corner *)
    | 9492 -> Uchar.of_char '|' (* '└' Bottom left corner *)
    | 9496 -> Uchar.of_char '|' (* '┘' Bottom right corner *)
    | 9500 -> Uchar.of_char '|' (* '├' Left T *)
    | 9508 -> Uchar.of_char '|' (* '┤' Right T *)
    | 9516 -> Uchar.of_char '|' (* '┬' Top T *)
    | 9524 -> Uchar.of_char '|' (* '┴' Bottom T *)
    | 9532 -> Uchar.of_char '|' (* '┼' Center cross *)
    | _ -> u)
;;

let to_string_markdown box =
  let ansi = PrintBox_text.to_string box in
  let lines = String.split_lines ansi in
  let lines = lines |> List.map ~f:to_md_line in
  String.concat ~sep:"\n" lines
;;
