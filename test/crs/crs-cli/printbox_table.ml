(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

(*_ This file was copied from the print-table test suite. *)
(****************************************************************************)
(*  print-table - Simple Unicode/ANSI and Markdown text table rendering     *)
(*  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: ISC                                            *)
(****************************************************************************)

(* This was mostly an experiment. We ended up implementing a direct rendering
   from [Print_table] to markdown without [PrintBox] intermediary. Keeping for
   experimentation (test dependencies only). *)

type t = PrintBox.t

let of_print_table t =
  let (Print_table.Private.Ast.T { columns; rows }) = Print_table.Private.to_ast t in
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
                               | Default | Dim | Underscore -> line text
                               | Fg_green -> line_with_style (Style.fg_color Green) text
                               | Fg_red -> line_with_style (Style.fg_color Red) text
                               | Fg_yellow -> line_with_style (Style.fg_color Yellow) text)
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
      Buffer.add_utf_8_uchar b (f u);
      loop d
    | `Malformed _ | `Await -> assert false
  in
  let d = Uutf.decoder (`String s) in
  loop d;
  Buffer.contents b
;;

let to_md_line s =
  map_utf8_string s ~f:(fun u ->
    match Uchar.to_int u with
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
