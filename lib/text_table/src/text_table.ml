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

let to_string_ansi = Text_table_ansi.to_string
let to_string_markdown = Text_table_markdown.to_string

module Style = struct
  include Text_table_ast.Style

  let default = Default
  let fg_green = Fg_green
  let fg_red = Fg_red
  let fg_yellow = Fg_yellow
end

module Cell = struct
  include Text_table_ast.Cell

  let empty = { style = Style.default; text = "" }
  let is_empty t = String.is_empty t.text
  let text ?(style = Style.default) text = { style; text }
end

module Align = struct
  include Text_table_ast.Align
end

module Column = struct
  include Text_table_ast.Column

  let make ~header ?(align = Align.Left) make_cell = { header; align; make_cell }
end

let make ~columns ~rows = Text_table_ast.T { columns; rows }

module O = struct
  module Align = Align
  module Cell = Cell
  module Column = Column
  module Style = Style
end

module Private = struct
  module Ast = Text_table_ast

  let to_ast t = t
end
