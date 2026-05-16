(**************************************************************************)
(*  crs-myers - Myers diff computation and unified-diff printing          *)
(*  Copyright (C) 2026 Mathieu Barbin <mathieu.barbin@gmail.com>          *)
(*  SPDX-License-Identifier: ISC                                          *)
(**************************************************************************)

(* Copyright (c) 2024-2026 Thomas Gazagnaire <thomas@gazagnaire.org>      *)
(* SPDX-License-Identifier: ISC                                           *)

(* Notice: This file was vendored from gazagnaire/ocaml-merge3 (the [Merge3]
   module, [lib/merge3.ml]) as documented in [vendor.json] and the project's
   root [NOTICE.md].

   List of changes:

   - Applied local project ocamlformat (janestreet profile).
   - Removed the parts unused by this project.

   - Replace use of globally-visible [Stdlib.Exit] exception by a custom one.
     An [eq] that itself raised [Exit] would be silently swallowed and yield
     a wrong diff. *)

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

type 'a edit =
  | Keep of 'a
  | Delete of 'a
  | Insert of 'a

(** Compute the furthest-reaching D-paths.

    Records snapshots of the active V range [-d..d] (size 2d+1) at each step
    instead of the full V array (size 2*max_d+1). This is the standard Myers
    space optimisation: at step d only diagonals -d..d are reachable, so the
    rest of V is unused. The trace becomes O(D²) instead of O(D*N), which is a
    substantial win when D ≪ N (typical for incremental edits).

    Returns [(D, trace)] where [trace.(d)] is an array of length [2*d+1] indexed
    by [k+d] (so trace.(d).(0) holds V[-d], trace.(d).(2*d) holds V[d]). *)

exception Myers_done

let myers_forward ~eq ~off a b ~max_d =
  let n = Array.length a
  and m = Array.length b in
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
         let x0 =
           if k = -d || (k <> d && v.(off + k - 1) < v.(off + k + 1))
           then v.(off + k + 1)
           else v.(off + k - 1) + 1
         in
         let x = ref x0
         and y = ref (x0 - k) in
         while !x < n && !y < m && eq a.(!x) b.(!y) do
           incr x;
           incr y
         done;
         v.(off + k) <- !x;
         if !x >= n && !y >= m
         then (
           final_d := d;
           raise_notrace Myers_done)
       done
     done
   with
   | Myers_done -> ());
  !final_d, trace
;;

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
  if is_insert
  then edits := Insert b.(snake_x - k - 1) :: !edits
  else edits := Delete a.(snake_x - 1) :: !edits;
  let prev_k = if is_insert then k + 1 else k - 1 in
  let prev_x = v_at prev_k in
  prev_x, prev_x - prev_k
;;

let diff ~eq (a : 'a array) (b : 'a array) : 'a edit list =
  let n = Array.length a
  and m = Array.length b in
  if n = 0 && m = 0
  then []
  else if n = 0
  then Array.to_list b |> List.map (fun x -> Insert x)
  else if m = 0
  then Array.to_list a |> List.map (fun x -> Delete x)
  else (
    let max_d = n + m in
    let off = max_d in
    let d, trace = myers_forward ~eq ~off a b ~max_d in
    let edits = ref [] in
    let x = ref n
    and y = ref m in
    for step = 0 to d - 1 do
      let dd = d - step in
      let nx, ny = backtrack_step ~vv:trace.(dd) ~dd ~x:!x ~y:!y a b edits in
      x := nx;
      y := ny
    done;
    for i = !x - 1 downto 0 do
      edits := Keep a.(i) :: !edits
    done;
    !edits)
;;
