(*_*************************************************************************)
(*_  crs-myers - Myers diff computation and unified-diff printing          *)
(*_  Copyright (C) 2026 Mathieu Barbin <mathieu.barbin@gmail.com>          *)
(*_  SPDX-License-Identifier: ISC                                          *)
(*_*************************************************************************)

(*_ Copyright (c) 2024-2026 Thomas Gazagnaire <thomas@gazagnaire.org>      *)
(*_ SPDX-License-Identifier: ISC                                           *)

(** Myers' O(ND) shortest-edit-script, vendored from gazagnaire/ocaml-merge3.

    Only the pure diff computation is vendored; see [merge3.ml] and the root
    [NOTICE.md] for the list of (non-algorithmic) parts removed. *)

(** An edit operation in the shortest edit script. *)
type 'a edit =
  | Keep of 'a (** Line present in both sequences. *)
  | Delete of 'a (** Line present in old, absent in new. *)
  | Insert of 'a (** Line absent in old, present in new. *)

(** [diff ~eq a b] computes the shortest edit script from [a] to [b] using
    Myers' O(ND) algorithm. [eq] is the equality predicate.

    The result is a list of edits that transforms [a] into [b]:
    - [Keep x]: line [x] is present in both
    - [Delete x]: line [x] from [a] is removed
    - [Insert x]: line [x] from [b] is added

    Time: O(ND) where N = |a| + |b| and D = edit distance. Space: O(D²) for the
    trace. *)
val diff : eq:('a -> 'a -> bool) -> 'a array -> 'a array -> 'a edit list
