(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

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
