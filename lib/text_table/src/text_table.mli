(*_*******************************************************************************)
(*_  crs - A tool for managing code review comments embedded in source code      *)
(*_  Copyright (C) 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>           *)
(*_                                                                              *)
(*_  This file is part of crs.                                                   *)
(*_                                                                              *)
(*_  crs is free software; you can redistribute it and/or modify it under the    *)
(*_  terms of the GNU Lesser General Public License as published by the Free     *)
(*_  Software Foundation either version 3 of the License, or any later version,  *)
(*_  with the LGPL-3.0 Linking Exception.                                        *)
(*_                                                                              *)
(*_  crs is distributed in the hope that it will be useful, but WITHOUT ANY      *)
(*_  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS   *)
(*_  FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License and     *)
(*_  the file `NOTICE.md` at the root of this repository for more details.       *)
(*_                                                                              *)
(*_  You should have received a copy of the GNU Lesser General Public License    *)
(*_  and the LGPL-3.0 Linking Exception along with this library. If not, see     *)
(*_  <http://www.gnu.org/licenses/> and <https://spdx.org>, respectively.        *)
(*_*******************************************************************************)

(** A minimalist interface to create ascii tables with Ansi and GitHub Flavored
    Markdown rendering.

    This library is inspired by [Textutils.Ascii_table] and [PrintBox]. We
    created it to implement the rendering to GitHub Markdown, which was not
    handled by either libraries.

    In the tests we show various rendering possible and compare it to [PrintBox]
    rendering (ansi, and markdown) for reference and experimentation. *)

type t

(** {1 Render} *)

val to_string_ansi : t -> string
val to_string_markdown : t -> string

(** {1 Builders} *)

module Style : sig
  type t

  val default : t
  val fg_red : t
end

module Cell : sig
  type t

  val empty : t
  val text : ?style:Style.t -> string -> t
end

module Align : sig
  type t =
    | Left
    | Center
    | Right
end

module Column : sig
  (** A type for a column extractor, parameterized by the type of the lines. *)
  type 'a t

  val make : header:string -> ?align:Align.t -> ('a -> Cell.t) -> 'a t
end

val make : columns:'a Column.t list -> rows:'a list -> t

module O : sig
  module Align = Align
  module Cell = Cell
  module Column = Column
  module Style = Style
end

(** {1 Private} *)

module Private : sig
  module Ast = Text_table_ast

  val to_ast : t -> Ast.t
end
