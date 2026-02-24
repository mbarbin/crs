(*_*******************************************************************************)
(*_  crs - A tool for managing inline review comments embedded in source code    *)
(*_  Copyright (C) 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>           *)
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

(** Given a range and the original file contents, extend the range to include
    surrounding whitespace up to the nearest newlines. This is useful when
    removing a CR that sits on its own line, so that the entire line is removed
    rather than leaving an empty line behind.

    - Left: extends through spaces and tabs backwards, stopping before a newline
      or non-whitespace character (neither included).
    - Right: extends through spaces and tabs forwards. A trailing newline is
      only included if the left extension reached a line boundary (beginning of
      file or preceded by a newline), preserving the line structure when the
      range follows code on the same line. *)
val extended_range : original_contents:string -> range:Loc.Range.t -> Loc.Range.t

(** Apply some rewrite after having parsed CRs from a file, and print the
    resulting diff showing the modifications performed. *)
val test
  :  path:Vcs.Path_in_repo.t
  -> file_contents:string
  -> f:(crs:Cr_comment.t list -> file_rewriter:File_rewriter.t -> unit)
  -> unit
