(**************************************************************************)
(*  crs-myers - Myers diff computation and unified-diff printing          *)
(*  Copyright (C) 2026 Mathieu Barbin <mathieu.barbin@gmail.com>          *)
(*  SPDX-License-Identifier: ISC                                          *)
(**************************************************************************)

(* Copyright (c) 2026 Invariant Systems. All rights reserved.             *)
(* SPDX-License-Identifier: ISC                                           *)

(* Notice: The unified-diff renderer and the [Equal] / [Line] / [compute] API
   shape in this file were vendored from windtrap (the [Myers] module,
   [lib/myers/myers.ml]) as documented in [vendor.json] and the project's root
   [NOTICE.md]. Only the shortest-edit-script computation was replaced (it now
   lives in [merge3.ml], vendored from gazagnaire/ocaml-merge3); the rendering
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

module type Equal = sig
  type t

  val equal : t -> t -> bool
end

module Line = struct
  (* Defined equal to [Merge3.edit] so [compute] needs no conversion and
     [Merge3] need not be exposed. *)
  type 'a t = 'a Merge3.edit =
    | Keep of 'a
    | Delete of 'a
    | Insert of 'a
end

let compute (type a) (module E : Equal with type t = a) (before : a list) (after : a list)
  : a Line.t list
  =
  Merge3.diff ~eq:E.equal (Array.of_list before) (Array.of_list after)
;;

let lines_of_string s =
  let parts = String.split_on_char '\n' s in
  match List.rev parts with
  | "" :: rev_rest -> List.rev rev_rest
  | _ -> parts
;;

type hunk =
  { exp_start : int
  ; exp_len : int
  ; act_start : int
  ; act_len : int
  ; lines : string Line.t list
  }

let hunks_of_lines ~context expected actual =
  let ops = compute (module String) expected actual in
  let pre = Queue.create () in
  let hunks_rev = ref [] in
  let in_hunk = ref false in
  let trailing = ref 0 in
  let cur_lines_rev = ref [] in
  let cur_exp_start = ref 0 in
  let cur_act_start = ref 0 in
  let cur_exp_len = ref 0 in
  let cur_act_len = ref 0 in
  let exp_line = ref 1 in
  let act_line = ref 1 in
  let queue_trim () =
    while Queue.length pre > context do
      ignore (Queue.take pre : string)
    done
  in
  let queue_to_list () =
    let acc = ref [] in
    Queue.iter (fun x -> acc := x :: !acc) pre;
    List.rev !acc
  in
  let start_hunk () =
    in_hunk := true;
    let pre_lines = queue_to_list () in
    Queue.clear pre;
    cur_lines_rev := List.rev_map (fun l -> Line.Keep l) pre_lines;
    cur_exp_start := !exp_line - List.length pre_lines;
    cur_act_start := !act_line - List.length pre_lines;
    cur_exp_len := List.length pre_lines;
    cur_act_len := List.length pre_lines;
    trailing := 0
  in
  let finish_hunk () =
    if !in_hunk
    then (
      let h =
        { exp_start = !cur_exp_start
        ; exp_len = !cur_exp_len
        ; act_start = !cur_act_start
        ; act_len = !cur_act_len
        ; lines = List.rev !cur_lines_rev
        }
      in
      hunks_rev := h :: !hunks_rev;
      cur_lines_rev := [];
      in_hunk := false;
      trailing := 0)
  in
  let add_hunk_line (line : string Line.t) =
    cur_lines_rev := line :: !cur_lines_rev;
    match line with
    | Keep _ ->
      cur_exp_len := !cur_exp_len + 1;
      cur_act_len := !cur_act_len + 1
    | Delete _ -> cur_exp_len := !cur_exp_len + 1
    | Insert _ -> cur_act_len := !cur_act_len + 1
  in
  List.iter
    (function
      | Line.Keep line ->
        if !in_hunk
        then
          if !trailing > 0
          then (
            add_hunk_line (Keep line);
            trailing := !trailing - 1)
          else (
            finish_hunk ();
            Queue.add line pre;
            queue_trim ())
        else (
          Queue.add line pre;
          queue_trim ());
        exp_line := !exp_line + 1;
        act_line := !act_line + 1
      | Line.Delete line ->
        if not !in_hunk then start_hunk ();
        add_hunk_line (Delete line);
        trailing := context;
        exp_line := !exp_line + 1
      | Line.Insert line ->
        if not !in_hunk then start_hunk ();
        add_hunk_line (Insert line);
        trailing := context;
        act_line := !act_line + 1)
    ops;
  finish_hunk ();
  List.rev !hunks_rev
;;

let diff ?(context = 3) ?expected_label ?actual_label expected actual =
  let a = lines_of_string expected in
  let b = lines_of_string actual in
  let hunks = hunks_of_lines ~context a b in
  let buf = Buffer.create 2048 in
  if Option.is_some expected_label || Option.is_some actual_label
  then
    Buffer.add_string
      buf
      (Printf.sprintf
         "--- %s\n+++ %s\n"
         (Option.value expected_label ~default:"expected")
         (Option.value actual_label ~default:"actual"));
  (* Reorder lines in each change group so deletions appear before insertions. *)
  let output_line (line : string Line.t) =
    Buffer.add_string
      buf
      (match line with
       | Delete line -> Printf.sprintf "-|%s\n" line
       | Insert line -> Printf.sprintf "+|%s\n" line
       | Keep line -> Printf.sprintf "  %s\n" line)
  in
  let flush_changes dels adds =
    List.iter output_line (List.rev dels);
    List.iter output_line (List.rev adds)
  in
  List.iter
    (fun h ->
       Buffer.add_string
         buf
         (Printf.sprintf
            "@@ -%d,%d +%d,%d @@\n"
            h.exp_start
            h.exp_len
            h.act_start
            h.act_len);
       let dels = ref [] in
       let adds = ref [] in
       List.iter
         (fun (line : string Line.t) ->
            match line with
            | Delete _ -> dels := line :: !dels
            | Insert _ -> adds := line :: !adds
            | Keep _ ->
              flush_changes !dels !adds;
              dels := [];
              adds := [];
              output_line line)
         h.lines;
       flush_changes !dels !adds)
    hunks;
  Buffer.contents buf
;;

let print_diff ?context ?expected_label ?actual_label expected actual =
  let text = diff ?context ?expected_label ?actual_label expected actual in
  print_string text
;;
