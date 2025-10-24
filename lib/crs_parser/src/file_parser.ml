(********************************************************************************)
(*  crs - A tool for managing code review comments embedded in source code      *)
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
 * - Compute positions and offsets with [Loc].
 * - Strip the ending of CR content.
 * - Migrate from [Re2] to [ocaml-re].
 *)

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

let find_ml_end =
  let regex = Re.compile Re.(alt [ str "(*"; str "*)" ]) in
  fun file_contents start_pos ->
    let rec nest_comments ~depth current_pos =
      match Re.exec_opt regex file_contents ~pos:current_pos with
      | None -> None
      | Some m ->
        let next_pos = Re.Group.stop m 0 in
        (match Re.Group.get m 0 with
         | "(*" -> nest_comments ~depth:(depth + 1) next_pos
         | "*)" ->
           if depth = 0
           then Some (next_pos - 2, next_pos)
           else nest_comments ~depth:(depth - 1) next_pos
         | _ ->
           failwith
             "ML regex matched something other than an ML comment start/end!"
           [@coverage off])
    in
    nest_comments ~depth:0 start_pos
;;

let find_non_nesting_end end_regex file_contents start_pos =
  match Re.exec_opt end_regex file_contents ~pos:(start_pos + 1) with
  | None -> None
  | Some m ->
    let start, stop = Re.Group.offset m 0 in
    Some (start, stop)
;;

let find_line_comment_end regex file_contents start_pos =
  match Re.exec_opt regex file_contents ~pos:(start_pos + 1) with
  | None ->
    (* reached EOF without finding a match, so block ends at EOF *)
    String.length file_contents - 1
  | Some m -> Re.Group.start m 0 - 1
;;

let find_comment_bounds =
  (* These end regexes are for matching the ends of block comments. *)
  let c_end_regex = Re.compile Re.(seq [ rep1 (char '*'); char '/' ]) in
  let xml_end_regex = Re.compile Re.(str "-->") in
  (* The line regexes match lines that DON'T start with a line comment marker. *)
  (* matches any character except [c], space, and tab *)
  let not_char c = Re.(compl [ char ' '; char '\t'; char c ]) in
  (* newline, followed by any amount of space *)
  let line_start = Re.(seq [ char '\n'; rep (alt [ char ' '; char '\t' ]) ]) in
  let sh_regex = Re.compile Re.(seq [ line_start; not_char '#' ]) in
  let lisp_regex = Re.compile Re.(seq [ line_start; not_char ';' ]) in
  (* The C line complicates things since it's two characters long.  The idea is that the
     line can optionally start with '/', but that can't be followed by another '/'. *)
  let c_line_regex = Re.compile Re.(seq [ line_start; opt (char '/'); not_char '/' ]) in
  let sql_regex = Re.compile Re.(seq [ line_start; opt (char '-'); not_char '-' ]) in
  fun file_contents content_start_pos ->
    let end_block kind comment_start_pos =
      let find_end =
        match kind with
        | `ml -> find_ml_end
        | `c -> find_non_nesting_end c_end_regex
        | `xml -> find_non_nesting_end xml_end_regex
      in
      match find_end file_contents content_start_pos with
      | None -> None
      | Some (end_contents, end_cr) ->
        let contents =
          (* string from "X?CR" to end of comment, excluding comment ender. *)
          String.sub
            file_contents
            ~pos:content_start_pos
            ~len:(end_contents - content_start_pos)
        in
        Some (comment_start_pos, end_cr - 1, contents)
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

let cr_pattern_egrep = "\\bX?CR[-v: \\t]"

let cr_regex =
  Re.compile
    Re.(
      seq
        [ bow
        ; opt (char 'X')
        ; str "CR"
        ; alt [ char '-'; char 'v'; char ':'; char ' '; char '\t' ]
        ])
;;

let condense_whitespace =
  let regex = Re.compile Re.(rep1 (set " \t\n")) in
  fun s -> Re.replace_string regex ~by:" " s
;;

let parse_file ~path ~(file_contents : Vcs.File_contents.t) =
  let file_contents = (file_contents :> string) in
  let file_cache =
    lazy (Loc.File_cache.create ~path:(Vcs.Path_in_repo.to_fpath path) ~file_contents)
  in
  let ms = Re.all cr_regex file_contents in
  let ( let* ) a f = Option.bind a ~f in
  List.filter_map ms ~f:(fun m ->
    let content_start_offset = Re.Group.start m 0 in
    let* start_offset, end_offset, content =
      find_comment_bounds file_contents content_start_offset
    in
    let content = String.rstrip content in
    let file_cache = Lazy.force file_cache in
    let header = Header_parser.parse ~file_cache ~content_start_offset ~content in
    let is_considered_a_CR =
      match header with
      | Ok _ -> true
      | Error _ ->
        (match Invalid_cr_parser.parse ~file_cache ~content_start_offset ~content with
         | Invalid_cr _ -> true
         | Not_a_cr -> false)
    in
    match is_considered_a_CR with
    | false -> None
    | true ->
      let comment_prefix =
        String.sub
          file_contents
          ~pos:start_offset
          ~len:(content_start_offset - start_offset)
        |> String.strip
      in
      let start_position = Loc.Offset.to_position start_offset ~file_cache in
      let stop_position = Loc.Offset.to_position (end_offset + 1) ~file_cache in
      let whole_loc = Loc.create (start_position, stop_position) in
      let digest_of_condensed_content =
        Cr_comment.Digest_hex.create (condense_whitespace content)
      in
      let cr_comment =
        Cr_comment.Private.create
          ~path
          ~whole_loc
          ~content_start_offset
          ~header
          ~comment_prefix
          ~digest_of_condensed_content
          ~content
      in
      Some cr_comment)
;;
