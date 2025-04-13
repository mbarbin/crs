(********************************************************************************)
(*  crs - A tool to parse code review comments embedded in source code          *)
(*  Copyright (C) 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>           *)
(*                                                                              *)
(*  This file is part of crs.                                                   *)
(*                                                                              *)
(*  crs is free software; you can redistribute it and/or modify it under the    *)
(*  terms of the GNU Lesser General Public License as published by the Free     *)
(*  Software Foundation either version 3 of the License, or any later version,  *)
(*  with the LGPL-3.0 Linking Exception.                                        *)
(*                                                                              *)
(*  crs is distributed in the hope that it will be useful, but WITHOUT ANY      *)
(*  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS   *)
(*  FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License and     *)
(*  the file `NOTICE.md` at the root of this repository for more details.       *)
(*                                                                              *)
(*  You should have received a copy of the GNU Lesser General Public License    *)
(*  and the LGPL-3.0 Linking Exception along with this library. If not, see     *)
(*  <http://www.gnu.org/licenses/> and <https://spdx.org>, respectively.        *)
(********************************************************************************)

(* This module is derived from Iron (v0.9.114.44+47), file
   * [./hg/cr_comment.ml], which is released under Apache 2.0:
   *
   * Copyright (c) 2016-2017 Jane Street Group, LLC <opensource-contacts@janestreet.com>
   *
   * Licensed under the Apache License, Version 2.0 (the "License"); you may not
   * use this file except in compliance with the License. You may obtain a copy
   * of the License at:
   *
   *     http://www.apache.org/licenses/LICENSE-2.0
   *
   * Unless required by applicable law or agreed to in writing, software
   * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
   * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
   * License for the specific language governing permissions and limitations
   * under the License.
   *
   * See the file `NOTICE.md` at the root of this repository for more details.
   *
   * Changes:
   *
   * - Migrate to this file only the part that relates to parsing files.
   * - Remove dependency to [Core] and [Async].
   * - Remove [Cr_comment_format].
   * - Replace [Unresolved_name] by [Vcs.User_handle].
   * - Remove alternate names and aliases resolution.
   * - Use [Vcs] instead of [Hg].
   * - Remove support for extra headers.
   * - Remove support for attributes.
   * - Remove assignee computation (left as external work).
*)

module Regex = Re2

(* supported comment syntaxes:

   ML     (* X?CR ... *)   may nest recursively

   C      /* X?CR ... */   may not nest recursively

   // X?CR ... EOL   may match multiple lines
   //      ... EOL
   //      ... EOL

   Shell  # X?CR  ... EOL
   #       ... EOL
   #       ... EOL

   Lisp   ; X?CR  ... EOL
   ;       ... EOL
   ;       ... EOL

   SQL    -- X?CR ... EOL
   --      ... EOL
   --      ... EOL

   XML    <!-- X?CR ... --> may not nest recursively
*)

let slice_after contents last_excluded_index =
  (* the longest suffix not containing [last_excluded_index] *)
  String.sub
    contents
    ~pos:(last_excluded_index + 1)
    ~len:(String.length contents - last_excluded_index - 1)
;;

(* several functions in Regex take a [sub] argument, but this is going to be [`Index 0]
   everywhere in this module, indicating that we're interested in the entire match *)
let sub = `Index 0

let find_ml_end =
  let regex = Regex.create_exn "\\(\\*|\\*\\)" in
  fun file_contents start_pos ->
    let rec nest_comments ~depth current_pos =
      let rest_of_file = slice_after file_contents current_pos in
      match Regex.get_matches_exn ~max:1 regex rest_of_file with
      | [] -> None
      | m :: _ ->
        let match_start, match_len = Regex.Match.get_pos_exn ~sub m in
        let next_pos = current_pos + match_start + match_len in
        (match Regex.Match.get_exn ~sub m with
         | "(*" -> nest_comments ~depth:(depth + 1) next_pos
         | "*)" ->
           if depth = 0 then Some next_pos else nest_comments ~depth:(depth - 1) next_pos
         | _ -> failwith "ML regex matched something other than an ML comment start/end!")
    in
    nest_comments ~depth:0 start_pos
;;

let find_non_nesting_end end_regex file_contents start_pos =
  let partial_contents = slice_after file_contents start_pos in
  match Regex.get_matches_exn ~max:1 end_regex partial_contents with
  | [] -> None
  | m :: _ ->
    let pos, len = Regex.Match.get_pos_exn ~sub m in
    Some (start_pos + pos + len)
;;

let find_line_comment_end regex file_contents start_pos =
  match Regex.get_matches_exn ~max:1 regex (slice_after file_contents start_pos) with
  | [] ->
    (* reached EOF without finding a match, so block ends at EOF *)
    String.length file_contents - 1
  | m :: _ ->
    let newline_pos, _ = Regex.Match.get_pos_exn ~sub m in
    start_pos + newline_pos
;;

let find_comment_bounds =
  (* These end regexes are for matching the ends of block comments. *)
  let ml_end_regex = Regex.create_exn "\\*+\\)$" in
  let c_end_regex = Regex.create_exn "\\*+/" in
  let xml_end_regex = Regex.create_exn "-->" in
  (* The line regexes match lines that DON'T start with a line comment marker. *)
  (* matches any character except [c], space, and tab *)
  let not_char c = "[^" ^ Char.to_string c ^ " \\t]" in
  (* newline, followed by any amount of space *)
  let line_start = "\\n[ \\t]*" in
  let sh_regex = Regex.create_exn (line_start ^ not_char '#') in
  let lisp_regex = Regex.create_exn (line_start ^ not_char ';') in
  (* The C line complicates things since it's two characters long.  The idea is that the
     line can optionally start with '/', but that can't be followed by another '/'. *)
  let c_line_regex = Regex.create_exn (line_start ^ "/?" ^ not_char '/') in
  let sql_regex = Regex.create_exn (line_start ^ "-?" ^ not_char '-') in
  fun file_contents content_start_pos ->
    let end_block kind comment_start_pos =
      let find_end, end_regex =
        match kind with
        | `ml -> find_ml_end, ml_end_regex
        | `c -> find_non_nesting_end c_end_regex, c_end_regex
        | `xml -> find_non_nesting_end xml_end_regex, xml_end_regex
      in
      match find_end file_contents content_start_pos with
      | None -> None
      | Some end_pos ->
        (* string from "X?CR" to end of comment (including comment ender) *)
        let raw_contents =
          String.sub
            file_contents
            ~pos:content_start_pos
            ~len:(end_pos + 1 - content_start_pos)
        in
        (* remove the comment ender *)
        let contents = Regex.rewrite_exn end_regex raw_contents ~template:"" in
        Some (comment_start_pos, end_pos, contents)
    in
    let end_lines regex comment_start_pos =
      let end_pos = find_line_comment_end regex file_contents content_start_pos in
      let contents =
        String.sub
          file_contents
          ~pos:content_start_pos
          ~len:(end_pos + 1 - content_start_pos)
      in
      comment_start_pos, end_pos, contents
    in
    (* Works backwards from "X?CR" to find a comment starter. *)
    let rec check_backwards ~last pos =
      let end_lines regex = Some (end_lines regex (pos + 1)) in
      if pos < 0
      then (
        match last with
        | `semi -> end_lines lisp_regex
        | `hash -> end_lines sh_regex
        | `slashes n -> if n >= 2 then end_lines c_line_regex else None
        | `dashes n -> if n >= 2 then end_lines sql_regex else None
        | `star | `not_special -> None)
      else (
        let curr_char = file_contents.[pos] in
        let check_backwards last = check_backwards ~last (pos - 1) in
        match last, curr_char with
        | `star, '*' -> check_backwards `star
        | `star, '/' -> end_block `c pos (* found /* *)
        | `star, '(' -> end_block `ml pos (* found "(*" (* "*)" *) *)
        | `star, _ -> None
        | `slashes n, '/' -> check_backwards (`slashes (n + 1))
        | `slashes n, _ -> if n >= 2 then end_lines c_line_regex (* found //+ *) else None
        | `semi, ';' -> check_backwards `semi
        | `semi, _ -> end_lines lisp_regex (* found ;+ *)
        | `hash, '#' -> check_backwards `hash
        | `hash, _ -> end_lines sh_regex (* found #+ *)
        | `dashes n, '-' -> check_backwards (`dashes (n + 1))
        | `dashes n, '!'
        (* checking if we found <!-- *)
          when n >= 2 && pos > 0 && Char.( = ) '<' file_contents.[pos - 1] ->
          end_block `xml (pos - 1)
        | `dashes n, _ -> if n >= 2 then end_lines sql_regex else None
        | `not_special, '/' -> check_backwards (`slashes 1)
        | `not_special, '*' -> check_backwards `star
        | `not_special, ';' -> check_backwards `semi
        | `not_special, '#' -> check_backwards `hash
        | `not_special, '-' -> check_backwards (`dashes 1)
        | `not_special, (' ' | '\t' | '\n') -> check_backwards `not_special
        | `not_special, _ -> None)
    in
    check_backwards ~last:`not_special (content_start_pos - 1)
;;

let index_to_2d_pos file_contents =
  (* Maps newline positions (indices of file_contents) to the number of the line they
     begin. *)
  let map, _last_line =
    let init = Map.singleton (module Int) (-1) 1, 1 in
    String.foldi file_contents ~init ~f:(fun pos ((map, prev_line) as acc) c ->
      if Char.equal c '\n'
      then (
        let curr_line = prev_line + 1 in
        Map.set map ~key:pos ~data:curr_line, curr_line)
      else acc)
  in
  `Staged
    (fun index ->
      match Map.closest_key map `Less_than index with
      | None -> failwith "gave a negative input to index_to_2d_pos"
      | Some (newline_index, line_num) -> line_num, index - newline_index)
;;

let cr_pattern_re2 = "\\bX?CR[-v: \\t]"
let cr_pattern_egrep = cr_pattern_re2
let cr_regex = Regex.create_exn cr_pattern_re2

let condense_whitespace =
  let regex = Regex.create_exn "\\s+" in
  fun s -> Regex.rewrite_exn regex ~template:" " s
;;

let extract ~path ~(file_contents : Vcs.File_contents.t) =
  let file_contents = (file_contents :> string) in
  let ms = Regex.get_matches_exn cr_regex file_contents in
  let pos_2d =
    lazy
      (match index_to_2d_pos file_contents with
       | `Staged f -> f)
  in
  List.filter_map ms ~f:(fun m ->
    let open Option.Let_syntax in
    let cr_start, _ = Regex.Match.get_pos_exn ~sub m in
    let%map start_index, _end_index, content =
      find_comment_bounds file_contents cr_start
    in
    let start_line, start_col = Lazy.force pos_2d start_index in
    let header = Header_parser.parse ~content in
    let digest_of_condensed_content =
      Cr_comment.Digest_hex.create (condense_whitespace content)
    in
    Cr_comment.Private.create
      ~path
      ~content
      ~start_line
      ~start_col
      ~header
      ~digest_of_condensed_content)
;;
