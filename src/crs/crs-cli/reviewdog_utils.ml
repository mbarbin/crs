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

let source : Reviewdog.Source.t =
  { name = "crs"; url = Some "https://github.com/mbarbin/crs" }
;;

let make_position (pos : Lexing.position) =
  { Reviewdog.Position.line = pos.pos_lnum; column = pos.pos_cnum - pos.pos_bol + 1 }
;;

let make_location (loc : Loc.t) =
  let path = Fpath.to_string (Loc.path loc) in
  let start_pos = Loc.start loc |> make_position in
  let end_pos = Loc.stop loc |> make_position in
  let range = { Reviewdog.Range.start = start_pos; end_ = Some end_pos } in
  { Reviewdog.Location.path; range = Some range }
;;
