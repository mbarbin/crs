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

module Column = struct
  type t =
    { header : string
    ; align : Text_table_ast.Align.t
    ; cells : Text_table_ast.Cell.t list
    ; length : int
    }
end

type t = { columns : Column.t array }

let of_text_table (Text_table_ast.T { columns; rows }) =
  let columns =
    Array.of_list_map columns ~f:(fun { header; align; make_cell } ->
      let cells = List.map rows ~f:(fun row -> make_cell row) in
      let length =
        List.fold cells ~init:0 ~f:(fun len cell -> Int.max len (String.length cell.text))
      in
      if length = 0
      then None
      else (
        let length = Int.max length (String.length header) in
        Some { Column.header; align; cells; length }))
    |> Array.filter_map ~f:Fn.id
  in
  { columns }
;;

let pad s ~len ~align =
  let slen = String.length s in
  if slen >= len
  then s
  else (
    let pad = String.make (len - slen) ' ' in
    match (align : Text_table_ast.Align.t) with
    | Left -> s ^ pad
    | Right -> pad ^ s
    | Center ->
      let left = (len - slen) / 2 in
      let right = len - slen - left in
      String.make left ' ' ^ s ^ String.make right ' ')
;;
