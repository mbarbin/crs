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

module Rdf = Reviewdog_rdf.Reviewdog

let source : Rdf.source = { name = "crs"; url = "https://github.com/mbarbin/crs" }

let location (loc : Loc.t) =
  let path = Fpath.to_string (Loc.path loc) in
  let start_pos = Loc.start loc in
  let stop_pos = Loc.stop loc in
  let start_line = Int32.of_int start_pos.pos_lnum in
  let start_col = Int32.of_int (start_pos.pos_cnum - start_pos.pos_bol + 1) in
  let stop_line = Int32.of_int stop_pos.pos_lnum in
  let stop_col = Int32.of_int (stop_pos.pos_cnum - stop_pos.pos_bol + 1) in
  let start_pb = Rdf.default_position ?line:start_line ?column:start_col () in
  let end_pb = Rdf.default_position ?line:stop_line ?column:stop_col () in
  let range = Rdf.default_range ~start:(Some start_pb) ~end_:(Some end_pb) () in
  Rdf.default_location ~path ~range:(Some range) ()
;;

let diagnostic (cr : Cr_comment.t) =
  match Cr_comment.work_on cr with
  | Soon | Someday -> None
  | Now ->
    let kind =
      match Cr_comment.header cr with
      | Error _ -> `Invalid
      | Ok _ -> `Now
    in
    let severity =
      match kind with
      | `Invalid -> Rdf.Warning
      | `Now -> Rdf.Info
    in
    let message =
      match kind with
      | `Invalid -> "This CR is not well formatted. Please attend."
      | `Now -> "This CR is pending. Please attend."
    in
    let loc = Cr_comment.whole_loc cr in
    let location = location loc in
    Some (Rdf.default_diagnostic ~message ~location:(Some location) ~severity ())
;;

let diagnostic_result crs =
  let diagnostics = List.filter_map crs ~f:diagnostic in
  Rdf.default_diagnostic_result ~diagnostics ~source:(Some source) ~severity:Info ()
;;
