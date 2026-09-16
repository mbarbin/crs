(*_***************************************************************************)
(*_  crs-merge3 - partial vendor of ocaml-merge3                             *)
(*_  SPDX-FileCopyrightText: 2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: ISC                                            *)
(*_***************************************************************************)

(*_ Notice: this file is a partial vendor of gazagnaire/ocaml-merge3
  ([lib/merge3.mli]), imported pristine at the revision recorded in
  [vendor.json] and then trimmed to the surface this project uses.
  ocamlformat is disabled in this directory ([.ocamlformat-ignore]) so that
  what remains stays byte-comparable with that revision.

  Upstream's copyright block and module header are kept as they stand, and
  so describe the whole of the upstream module rather than this trimmed
  copy.

  Removed: [lcs]; the 3-way merge section ([merge], [has_conflicts],
  [to_string], [conflicts] and [pp], and the [conflict], [merged_chunk] and
  [t] types); and the Irmin-style merge combinators ([result], [f],
  [default], [option], [pair], [alist]). *)

(* Copyright (c) 2024-2026 Thomas Gazagnaire <thomas@gazagnaire.org>

   Permission to use, copy, modify, and distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE. *)

(** Textbook 3-way merge algorithms.

    [Merge3] computes the shortest edit script between two sequences, and merges
    two derived versions of a text against their common ancestor.

    {2:algorithms Algorithms}

    {b Myers diff.} The shortest edit script between two sequences in O(ND)
    time, where N is the total length and D the edit distance. Near-linear for
    similar inputs.

    {i E. W. Myers, "An O(ND) Difference Algorithm and Its Variations",
       Algorithmica 1(2), 1986, pp. 251-266.}

    {b diff3 merge.} Given a common ancestor (base) and two derived versions, a
    merged result or conflict markers.

    {i S. Khanna, K. Kuber, B. C. Pierce, "A Formal Investigation of Diff3",
       FSTTCS 2007, LNCS 4855, pp. 485-496.} *)

(** {1:diff Diff} *)

(** The type for edit operations in a shortest edit script. *)
type 'a edit =
  | Keep of 'a  (** Element present in both sequences. *)
  | Delete of 'a  (** Element present in the old sequence, absent in the new. *)
  | Insert of 'a  (** Element absent in the old sequence, present in the new. *)

val diff : eq:('a -> 'a -> bool) -> 'a array -> 'a array -> 'a edit list
(** [diff ~eq a b] is the shortest edit script transforming [a] into [b], by
    Myers' O(ND) algorithm, with elements compared by [eq]. It runs in O(ND)
    time for N the sum of the lengths of [a] and [b] and D the edit distance,
    and holds the trace in O(D{^ 2}) space. *)
