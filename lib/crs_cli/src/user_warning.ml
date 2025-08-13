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

let pp_to_string pp =
  let buffer = Buffer.create 23 in
  let formatter = Stdlib.Format.formatter_of_buffer buffer in
  Stdlib.Format.fprintf formatter "%a%!" Pp.to_fmt pp;
  let contents =
    Buffer.contents buffer
    |> String.split_lines
    |> List.map ~f:(fun s -> String.rstrip s ^ "\n")
    |> String.concat
  in
  contents
;;

let emit ?loc ~print_gh_annotation_warnings ?hints messages =
  Err.warning ?loc ?hints messages;
  if print_gh_annotation_warnings
  then (
    let message_text = String.concat ~sep:"" (List.map messages ~f:pp_to_string) in
    let hints_text =
      match hints with
      | None -> ""
      | Some hints -> "Hints: " ^ String.concat ~sep:" " (List.map hints ~f:pp_to_string)
    in
    let github_annotation =
      Github_annotation.create
        ~loc:(Option.value loc ~default:Loc.none)
        ~severity:Warning
        ~title:"crs"
        ~message:(String.strip (message_text ^ hints_text))
    in
    prerr_endline (Github_annotation.to_string github_annotation))
;;
