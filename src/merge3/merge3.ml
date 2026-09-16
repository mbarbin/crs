(****************************************************************************)
(*  crs-merge3 - partial vendor of ocaml-merge3                             *)
(*  SPDX-FileCopyrightText: 2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: ISC                                            *)
(****************************************************************************)

(* Notice: this file is a partial vendor of gazagnaire/ocaml-merge3
   ([lib/merge3.ml]), imported pristine at the revision recorded in
   [vendor.json] and then trimmed to the surface this project uses.
   ocamlformat is disabled in this directory ([.ocamlformat-ignore]) so that
   what remains stays byte-comparable with that revision.

   Upstream's copyright block and module header are kept as they stand, and
   so describe the whole of the upstream module rather than this trimmed
   copy.

   Removed: [lcs]; the diff3 3-way merge ([merge], [to_string],
   [has_conflicts] and [conflicts], the [conflict], [merged_chunk] and [t]
   types, and their machinery); [pp], the only user of the [fmt] dependency;
   and the Irmin-style merge combinators ([result], [f], [default],
   [option], [pair], [alist]).

   Changed: [myers_forward] ends its search on its own [Myers_done]
   exception rather than [Stdlib.Exit], which an [eq] that itself raises
   [Exit] would be caught by. *)

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

(** {1 Myers' O(ND) Diff Algorithm}

    E. W. Myers, "An O(ND) Difference Algorithm and Its Variations",
    Algorithmica 1(2), 1986, pp. 251–266.

    The algorithm finds the shortest edit script (SES) between two sequences. It
    works by computing the furthest-reaching D-paths for increasing edit
    distances D = 0, 1, 2, ... The key insight is that diagonal k = x - y
    represents a state where x characters from [a] and y from [b] have been
    consumed, and only even/odd diagonals are reachable at each step.

    Time: O(ND) where N = |a| + |b| and D = edit distance. Space: O(D²) for the
    trace (one V-array per step). *)

type 'a edit = Keep of 'a | Delete of 'a | Insert of 'a

let myers_next_x v off d k =
  if k = -d || (k <> d && v.(off + k - 1) < v.(off + k + 1)) then
    v.(off + k + 1)
  else v.(off + k - 1) + 1

let myers_extend_snake ~eq a b ~n ~m ~x0 ~k =
  let x = ref x0 and y = ref (x0 - k) in
  while !x < n && !y < m && eq a.(!x) b.(!y) do
    incr x;
    incr y
  done;
  (!x, !y)

let myers_forward_diagonal ~eq a b ~n ~m v ~off ~d ~k =
  let x0 = myers_next_x v off d k in
  let x, y = myers_extend_snake ~eq a b ~n ~m ~x0 ~k in
  v.(off + k) <- x;
  x >= n && y >= m

exception Myers_done

(** Compute the furthest-reaching D-paths.

    Records snapshots of the active V range [-d..d] (size 2d+1) at each step
    instead of the full V array (size 2*max_d+1). This is the standard Myers
    space optimisation: at step d only diagonals -d..d are reachable, so the
    rest of V is unused. The trace becomes O(D²) instead of O(D*N), which is a
    substantial win when D ≪ N (typical for incremental edits).

    Returns [(D, trace)] where [trace.(d)] is an array of length [2*d+1] indexed
    by [k+d] (so trace.(d).(0) holds V[-d], trace.(d).(2*d) holds V[d]). *)
let myers_forward ~eq ~off a b ~max_d =
  let n = Array.length a and m = Array.length b in
  let vlen = (2 * max_d) + 1 in
  let v = Array.make vlen 0 in
  v.(off + 1) <- 0;
  let trace = Array.make (max_d + 1) [||] in
  let final_d = ref 0 in
  (try
     for d = 0 to max_d do
       (* Snapshot only the active range used at step d (diagonals -d..d). *)
       trace.(d) <- Array.sub v (off - d) ((2 * d) + 1);
       for k0 = 0 to d do
         let k = -d + (2 * k0) in
         if myers_forward_diagonal ~eq a b ~n ~m v ~off ~d ~k then begin
           final_d := d;
           raise_notrace Myers_done
         end
       done
     done
   with Myers_done -> ());
  (!final_d, trace)

(** Backtrack one step in the Myers trace, emitting the snake's [Keep]
    operations and the single non-diagonal edit. Returns the previous [(x, y)]
    position.

    [vv] is the snapshot at step [dd]: an array of length [2*dd+1] where
    [vv.(k+dd)] holds the V value for diagonal [k]. *)
let backtrack_step ~vv ~dd ~x ~y a b edits =
  let k = x - y in
  (* The previous snapshot only has diagonals -(dd-1)..(dd-1), but we read
     V[k-1] and V[k+1] from the current step's snapshot — those are guaranteed
     to be in range because k ∈ [-dd, dd] and k±1 ∈ [-(dd+1), dd+1], but
     critically when we make the choice we look at V[k-1] and V[k+1] from
     the SAME snapshot (saved at the start of step dd, which is the V state
     after step dd-1), so they're both in [-(dd-1), dd-1] ⊆ [-dd, dd]. *)
  let v_at i = vv.(i + dd) in
  let is_insert = k = -dd || (k <> dd && v_at (k - 1) < v_at (k + 1)) in
  let snake_x = if is_insert then v_at (k + 1) else v_at (k - 1) + 1 in
  for i = x - 1 downto snake_x do
    edits := Keep a.(i) :: !edits
  done;
  if is_insert then edits := Insert b.(snake_x - k - 1) :: !edits
  else edits := Delete a.(snake_x - 1) :: !edits;
  let prev_k = if is_insert then k + 1 else k - 1 in
  let prev_x = v_at prev_k in
  (prev_x, prev_x - prev_k)

let diff ~eq (a : 'a array) (b : 'a array) : 'a edit list =
  let n = Array.length a and m = Array.length b in
  if n = 0 && m = 0 then []
  else if n = 0 then Array.to_list b |> List.map (fun x -> Insert x)
  else if m = 0 then Array.to_list a |> List.map (fun x -> Delete x)
  else
    let max_d = n + m in
    let off = max_d in
    let d, trace = myers_forward ~eq ~off a b ~max_d in
    let edits = ref [] in
    let x = ref n and y = ref m in
    for step = 0 to d - 1 do
      let dd = d - step in
      let nx, ny = backtrack_step ~vv:trace.(dd) ~dd ~x:!x ~y:!y a b edits in
      x := nx;
      y := ny
    done;
    for i = !x - 1 downto 0 do
      edits := Keep a.(i) :: !edits
    done;
    !edits
