(**************************************************************************)
(*  Copyright (c) 2026 Invariant Systems. All rights reserved.            *)
(*  SPDX-License-Identifier: ISC                                          *)
(**************************************************************************)

(* Notice: This file was vendored from windtrap.myers as documented in
   [vendor.json] and the project's root [NOTICE.md].

   List of changes:

   - Applied local project ocamlformat.
   - Small changes to the diff rendering.
   - Use [Lind] in more places instead of (char * string) encoding.
   - Use [raise_notrace] for the local exception.
*)

module type Equal = sig
  type t

  val equal : t -> t -> bool
end

module Line = struct
  type 'a t =
    | Delete of 'a
    | Insert of 'a
    | Keep of 'a
end

exception Found of int * int array list

let compute
      (type a)
      (module Equal : Equal with type t = a)
      (before : a list)
      (after : a list)
  =
  let a = Array.of_list before in
  let b = Array.of_list after in
  let n = Array.length a in
  let m = Array.length b in
  let max_d = n + m in
  if max_d = 0
  then []
  else (
    let offset = max_d in
    let v = Array.make ((2 * max_d) + 1) (-1) in
    v.(offset + 1) <- 0;
    let traces_rev = ref [] in
    try
      for d = 0 to max_d do
        for k = -d to d do
          if (k + d) mod 2 = 0
          then (
            let x =
              if k = -d || (k <> d && v.(offset + k - 1) < v.(offset + k + 1))
              then v.(offset + k + 1)
              else if k = d
              then v.(offset + k - 1) + 1
              else (
                let x1 = v.(offset + k - 1) + 1 in
                let x2 = v.(offset + k + 1) in
                if x1 > x2 then x1 else x2)
            in
            let y = x - k in
            let x, y =
              let x = ref x in
              let y = ref y in
              while !x < n && !y < m && Equal.equal a.(!x) b.(!y) do
                incr x;
                incr y
              done;
              !x, !y
            in
            v.(offset + k) <- x;
            if x >= n && y >= m
            then (
              traces_rev := Array.copy v :: !traces_rev;
              raise_notrace (Found (d, List.rev !traces_rev))))
        done;
        traces_rev := Array.copy v :: !traces_rev
      done;
      []
    with
    | Found (d_final, traces) ->
      let traces = Array.of_list traces in
      let x = ref n in
      let y = ref m in
      let ops = ref [] in
      for d = d_final downto 1 do
        let k = !x - !y in
        let prev = traces.(d - 1) in
        let prev_k =
          if k = -d || (k <> d && prev.(offset + k - 1) < prev.(offset + k + 1))
          then k + 1
          else k - 1
        in
        let prev_x = prev.(offset + prev_k) in
        let prev_y = prev_x - prev_k in
        while !x > prev_x && !y > prev_y do
          ops := Line.Keep a.(!x - 1) :: !ops;
          decr x;
          decr y
        done;
        if prev_k = k + 1
        then ops := Line.Insert b.(prev_y) :: !ops
        else ops := Line.Delete a.(prev_x) :: !ops;
        x := prev_x;
        y := prev_y
      done;
      while !x > 0 && !y > 0 do
        ops := Line.Keep a.(!x - 1) :: !ops;
        decr x;
        decr y
      done;
      while !x > 0 do
        ops := Line.Delete a.(!x - 1) :: !ops;
        decr x
      done;
      while !y > 0 do
        ops := Line.Insert b.(!y - 1) :: !ops;
        decr y
      done;
      !ops)
;;

type hunk =
  { exp_start : int
  ; exp_len : int
  ; act_start : int
  ; act_len : int
  ; lines : string Line.t list
  }

let lines_of_string s =
  let parts = String.split_on_char '\n' s in
  match List.rev parts with
  | "" :: rev_rest -> Array.of_list (List.rev rev_rest)
  | _ -> Array.of_list parts
;;

let hunks_of_lines ~context expected actual =
  let module Eq = struct
    type t = string

    let equal = String.equal
  end
  in
  let ops = compute (module Eq) (Array.to_list expected) (Array.to_list actual) in
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
