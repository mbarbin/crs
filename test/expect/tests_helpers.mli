(*_********************************************************************************)
(*_  crs - A tool for managing inline review comments embedded in source code     *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*_********************************************************************************)

(** Given a range and the original file contents, extend the range to include
    surrounding whitespace up to the nearest newlines. This is useful when
    removing a CR that sits on its own line, so that the entire line is removed
    rather than leaving an empty line behind.

    - Left: extends through spaces and tabs backwards, stopping before a newline
      or non-whitespace character (neither included).
    - Right: extends through spaces and tabs forwards. A trailing newline is
      only included if the left extension reached a line boundary (beginning of
      file or preceded by a newline), preserving the line structure when the
      range follows code on the same line.
    - When code is present on both sides (not at a line boundary, and the right
      extension stops at a non-newline character), one space is preserved on the
      left so that adjacent tokens remain properly separated
      (e.g. removing a comment from ["let () = (* ... *) ()"] yields
      ["let () = ()"] rather than ["let () =()"]. *)
val extended_range : original_contents:string -> range:Loc.Range.t -> Loc.Range.t

(** Apply some rewrite after having parsed CRs from a file, and print the
    resulting diff showing the modifications performed. *)
val test
  :  path:Vcs.Path_in_repo.t
  -> file_contents:string
  -> f:(crs:Cr_comment.t list -> file_rewriter:File_rewriter.t -> unit)
  -> unit
