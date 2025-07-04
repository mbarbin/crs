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

(** An intermediate data structure used in the rendering of text tables. *)

module Column : sig
  type t = private
    { header : string
    ; align : Text_table_ast.Align.t
    ; cells : Text_table_ast.Cell.t list
    ; length : int
    }
end

(** Due to the type being [private] we can guarantee that each column has the
    same number of cells. *)
type t = private { columns : Column.t array }

val of_text_table : Text_table_ast.t -> t

(** {1 Utils} *)

(** [pad input ~len ~align] returns a new string with spaces either to the left,
    right or both so that it contains the original string at the specified
    alignment. For example [pad "hello" 10 ~align:Right] is equivalent to
    [String.make 5 ' ' ^ "hello"]. *)
val pad : string -> len:int -> align:Text_table_ast.Align.t -> string
