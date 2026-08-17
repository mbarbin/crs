(*_***************************************************************************)
(*_  crs-myers - Myers diff computation and unified-diff printing            *)
(*_  SPDX-FileCopyrightText: 2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: ISC                                            *)
(*_***************************************************************************)

(*_ Copyright (c) 2026 Invariant Systems. All rights reserved.

  Permission to use, copy, modify, and/or distribute this software for any
  purpose with or without fee is hereby granted, provided that the above
  copyright notice and this permission notice appear in all copies.

  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE. *)

(*_ Notice: The unified-diff renderer and the [Equal] / [Line] / [compute] API
  shape in this file were vendored from windtrap (the [Myers] module,
  [lib/myers/myers.mli]) as documented in [vendor.json] and the project's root
  [NOTICE.md]. Only the shortest-edit-script computation was replaced (it now
  lives in [merge3.mli], vendored from gazagnaire/ocaml-merge3); the rendering
  logic — [type hunk], [lines_of_string], [hunks_of_lines], [diff],
  [print_diff] — derives from windtrap.

  List of changes relative to windtrap:

  - Applied local project ocamlformat (janestreet profile).
  - [compute] delegates to the vendored {!Merge3.diff}.
  - Hunk lines use the [Line] variant instead of windtrap's [(char * string)]
    encoding ([type hunk.lines : string Line.t list]).
  - [lines_of_string] returns a [string list] and the intermediate [Array]
    representation in [hunks_of_lines] was removed.
  - Diff rendering tweaks: line prefixes are ["-|"] / ["+|"] / ["  "], and the
    [--- / +++] header is emitted only when a label is explicitly provided
    (windtrap always emitted it with the defaults "expected" / "actual"). *)

(** Unified-diff renderer built on a vendored Myers shortest-edit-script.

    The renderer is vendored from windtrap; the shortest-edit-script
    computation is vendored from gazagnaire/ocaml-merge3 (kept as a private
    [Merge3] module). See [myers.ml], [merge3.ml] and the root [NOTICE.md] for
    provenance and the list of changes. *)

module type Equal = sig
  type t

  val equal : t -> t -> bool
end

module Line : sig
  type 'a t =
    | Keep of 'a
    | Delete of 'a
    | Insert of 'a
end

(** [compute (module E) before after] returns a shortest edit script from
    [before] to [after], computed with Myers' O(ND) algorithm. *)
val compute : (module Equal with type t = 'a) -> 'a list -> 'a list -> 'a Line.t list

(** [diff expected actual] renders a unified diff for text inputs. *)
val diff
  :  ?context:int
  -> ?expected_label:string
  -> ?actual_label:string
  -> string
  -> string
  -> string

(** [print_diff expected actual] writes {!diff} to stdout. *)
val print_diff
  :  ?context:int
  -> ?expected_label:string
  -> ?actual_label:string
  -> string
  -> string
  -> unit
