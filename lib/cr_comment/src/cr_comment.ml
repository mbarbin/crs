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
   * - Remove dependency to [Core] - make small adjustments to use [Base] instead.
   * - Remove dependency to [Async] - replace by [Shexp] and [Stdio].
   * - Remove the [Stable] module - do not version the code.
   * - Remove [bin_io] and [bin_digest] expect tests.
   * - Remove [hash_consing] constructs - do not share the values.
   * - Replace [Relpath] by [Vcs.Path_in_repo].
   * - Remove [of_sexp] constructs.
   * - Replace [Unresolved_name] by [Vcs.User_handle].
   * - Remove [deriving fields] ppx constructs.
   * - Remove alternate names and aliases resolution.
   * - Remove incremental computation features.
   * - Remove summary tables.
   * - Introduce a local module for digests.
   * - Remove verbose and debug logs.
   * - Rewrite [String.slice] calls as equivalent [String.sub] calls.
   * - Remove invariant checks.
   * - Use [Vcs] instead of [Hg].
   * - Remove [Crs_due_now_and_soon].
   * - Remove support for in-file `Properties.
   * - Remove support for extra headers.
*)

module Regex = Re2

module Digest_hex = struct
  type t = string [@@deriving compare, sexp_of]

  let hash = String.hash
  let create str = str |> Stdlib.Digest.string |> Stdlib.Digest.to_hex
end

let cr_pattern_re2 = "\\bX?CR[-v: \\t]"
let cr_pattern_egrep = cr_pattern_re2

module Raw : sig
  type t =
    { path : Vcs.Path_in_repo.t
    ; content : string
    ; start_line : int
    ; start_col : int
    }
  [@@deriving compare, sexp_of]

  val content : t -> string

  module For_sorted_output : sig
    type nonrec t = t [@@deriving compare]
  end

  module With_file_positions : sig
    type nonrec t =
      { content_start : int
      ; start_index : int
      ; end_index : int
      ; cr : t
      }
    [@@deriving sexp_of]

    val extract : path:Vcs.Path_in_repo.t -> file_contents:string -> unit -> t list
  end
end = struct
  (* [content] is the text of the CR with comment markers removed from the beginning
     and end (if applicable).

     [start_line, start_col] is the two-dimensional start position of the whole
     comment in [path]. *)
  type t =
    { path : Vcs.Path_in_repo.t
    ; content : string
    ; start_line : int
    ; start_col : int
    }
  [@@deriving compare, sexp_of]

  let content t = t.content

  module For_sorted_output = struct
    type nonrec t = t

    let compare t1 t2 =
      let c = Vcs.Path_in_repo.compare t1.path t2.path in
      if c <> 0
      then c
      else (
        let c = Int.compare t1.start_line t2.start_line in
        if c <> 0 then c else Int.compare t1.start_col t2.start_col)
    ;;
  end

  let cr_regex = Regex.create_exn cr_pattern_re2

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
             if depth = 0
             then Some next_pos
             else nest_comments ~depth:(depth - 1) next_pos
           | _ ->
             failwith "ML regex matched something other than an ML comment start/end!")
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
          | `slashes n, _ ->
            if n >= 2 then end_lines c_line_regex (* found //+ *) else None
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

  module With_file_positions = struct
    type nonrec t =
      { content_start : int
      ; start_index : int
      ; end_index : int
      ; cr : t
      }
    [@@deriving sexp_of]

    let extract ~path ~file_contents () =
      let ms = Regex.get_matches_exn cr_regex file_contents in
      let pos_2d =
        lazy
          (match index_to_2d_pos file_contents with
           | `Staged f -> f)
      in
      List.filter_map ms ~f:(fun m ->
        let open Option.Let_syntax in
        let cr_start, _ = Regex.Match.get_pos_exn ~sub m in
        let%map start_index, end_index, content =
          find_comment_bounds file_contents cr_start
        in
        let start_line, start_col = Lazy.force pos_2d start_index in
        { content_start = cr_start
        ; start_index
        ; end_index
        ; cr = { path; content; start_line; start_col }
        })
    ;;
  end
end

module Due = struct
  type t =
    | Now
    | Soon
    | Someday
  [@@deriving compare, sexp_of]
end

let missing_file_owner = Vcs.User_handle.v "missing-file-owner"

module Assignee = struct
  type t =
    | This of Vcs.User_handle.t
    | Feature_owner
    | Missing_file_owner
  [@@deriving compare, sexp_of]

  let user_name t ~feature_owner =
    match t with
    | This unresolved_name -> unresolved_name
    | Feature_owner -> feature_owner
    | Missing_file_owner -> missing_file_owner
  ;;
end

module Processed = struct
  (* [reported_by] is [user] in [CR user...].  It is an [option] because the text
     might not have a valid user name.

     [for_] is [user2] in [CR user1 for user2: ...].

     Names stored in [Processed.t] have not yet been dealiased, so they are stored as
     [Unresolve_name.t]s. *)
  type t =
    { raw : Raw.t
    ; reported_by : Vcs.User_handle.t option
    ; for_ : Vcs.User_handle.t option
    ; due : Due.t
    ; is_xcr : bool
    ; assignee : Assignee.t
    }
  [@@deriving compare, sexp_of]

  let compute_assignee ~file_owner ~reported_by ~for_ ~due ~is_xcr =
    if is_xcr
    then (
      match reported_by with
      | None -> Assignee.Feature_owner
      | Some user -> This user)
    else (
      match for_ with
      | Some user -> This user
      | None ->
        (match (due : Due.t) with
         | Now -> Feature_owner
         | Soon | Someday ->
           (match file_owner with
            | None -> Assignee.Missing_file_owner
            | Some user -> This user)))
  ;;
end

type t =
  | Raw of Raw.t
  | Processed of Processed.t
[@@deriving compare, sexp_of]

type cr_comment = t [@@deriving sexp_of]

let hash (t : t) = Hashtbl.hash t

let raw t =
  match t with
  | Raw r -> r
  | Processed p -> p.raw
;;

let path t = (raw t).path
let content t = (raw t).content
let start_line t = (raw t).start_line
let start_col t = (raw t).start_col

let reindented_content t =
  let indent = String.make ((raw t).start_col + 2) ' ' in
  let str = content t in
  let lines = String.split str ~on:'\n' in
  let lines =
    lines
    |> List.rev
    |> List.drop_while ~f:(String.for_all ~f:Char.is_whitespace)
    |> List.rev
  in
  match
    Result.try_with (fun () ->
      List.mapi lines ~f:(fun i s ->
        match String.chop_prefix s ~prefix:indent with
        | None ->
          if String.is_prefix indent ~prefix:s
          then ""
          else if i = 0
          then "  " ^ s
          else raise Stdlib.Exit
        | Some s -> "  " ^ s))
  with
  | (exception Stdlib.Exit) | Error _ -> str
  | Ok deindented_lines -> String.concat deindented_lines ~sep:"\n"
;;

module Structurally_compared = struct
  type nonrec t = t [@@deriving compare, sexp_of]
end

module For_sorted_output = struct
  type nonrec t = t

  let compare t1 t2 = Raw.For_sorted_output.compare (raw t1) (raw t2)
end

let sort ts = List.sort ts ~compare:For_sorted_output.compare

let assignee t =
  match t with
  | Raw _ -> Assignee.Feature_owner
  | Processed p -> p.assignee
;;

let due t =
  match t with
  | Raw _ -> Due.Now
  | Processed p -> p.due
;;

let is_xcr t =
  match t with
  | Raw _ -> false
  | Processed p -> p.is_xcr
;;

let work_on t : Due.t =
  match t with
  | Raw _ -> Now
  | Processed p -> if p.is_xcr then Now else p.due
;;

let to_string ?(attributes = []) t ~include_content =
  let file_str =
    Printf.sprintf
      "%s:%d:%d:"
      (Vcs.Path_in_repo.to_string (path t))
      (start_line t)
      (start_col t)
  in
  let attributes =
    match attributes with
    | [] -> []
    | _ :: _ ->
      let max_width =
        List.fold_left attributes ~init:0 ~f:(fun acc (k, _) -> max acc (String.length k))
      in
      List.map attributes ~f:(fun (k, v) -> Printf.sprintf "%-*s : %s" max_width k v)
  in
  let contents = if include_content then [ reindented_content t ] else [] in
  String.concat ~sep:"\n" ((file_str :: attributes) @ contents @ [ "" ])
;;

let print ~attributes ~include_delim cr ~include_content =
  let str = to_string cr ~attributes ~include_content in
  let nl = if include_delim && include_content then "\n" else "" in
  print_string (Printf.sprintf "%s%s" nl str)
;;

let print_list ~crs_and_attributes ~include_content =
  let crs_and_attributes =
    List.sort crs_and_attributes ~compare:(fun (cr, _) (cr2, _) ->
      For_sorted_output.compare cr cr2)
  in
  let include_delim = ref false in
  List.iter crs_and_attributes ~f:(fun (cr, attributes) ->
    print ~attributes ~include_delim:!include_delim cr ~include_content;
    include_delim := true)
;;

module Cr_soon = struct
  module T = struct
    type t =
      { cr_comment : Processed.t
      ; digest_of_condensed_content : Digest_hex.t
      ; hash_of_path_and_condensed_content : int
      }
    [@@deriving compare, sexp_of]
  end

  include T

  let condense_whitespace =
    let regex = Regex.create_exn "\\s+" in
    fun s -> Regex.rewrite_exn regex ~template:" " s
  ;;

  let create ~(cr_comment : cr_comment) =
    try
      match cr_comment with
      | Raw _ -> failwith "a raw CR comment cannot be a CR-soon"
      | Processed cr_comment ->
        let raw = cr_comment.raw in
        let digest_of_condensed_content =
          Digest_hex.create (condense_whitespace raw.content)
        in
        let t =
          { cr_comment
          ; digest_of_condensed_content
          ; hash_of_path_and_condensed_content =
              Vcs.Path_in_repo.hash raw.path
              lxor Digest_hex.hash digest_of_condensed_content
          }
        in
        let () =
          assert (not cr_comment.is_xcr);
          assert (
            match cr_comment.due with
            | Soon -> true
            | Now | Someday -> false)
        in
        Ok t
    with
    | exn ->
      Or_error.error
        "Cr_soon.create failed"
        (exn, cr_comment)
        [%sexp_of: exn * cr_comment]
  ;;

  let cr_comment t = Processed t.cr_comment

  let assignee t =
    match t.cr_comment.assignee with
    | Feature_owner -> assert false
    | This user_name -> user_name
    | Missing_file_owner -> missing_file_owner
  ;;

  let raw t = t.cr_comment.raw
  let start_line t = (raw t).start_line
  let path t = (raw t).path
  let content t = (raw t).content

  module Structurally_compared = struct
    type nonrec t = t [@@deriving compare, sexp_of]
  end

  module Compare_ignoring_minor_text_changes = struct
    module T = struct
      include T

      let hash t = t.hash_of_path_and_condensed_content
      let hash_fold_t state t = Hash.fold_int state (hash t)

      let compare t1 t2 =
        let c = Int.compare (hash t1) (hash t2) in
        if c <> 0
        then c
        else (
          let c =
            Digest_hex.compare
              t1.digest_of_condensed_content
              t2.digest_of_condensed_content
          in
          if c <> 0
          then c
          else (
            let c = Vcs.Path_in_repo.compare (path t1) (path t2) in
            if c <> 0 then c else Vcs.User_handle.compare (assignee t1) (assignee t2)))
      ;;
    end

    include T
    include Comparable.Make (T)
  end

  module For_sorted_output = struct
    type nonrec t = t

    let compare t1 t2 = Raw.For_sorted_output.compare (raw t1) (raw t2)
  end
end

(* -------------------------------------------------------------------------- *)
(*  Matching                                                                  *)
(* -------------------------------------------------------------------------- *)

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

module Process : sig
  val process : Raw.t -> file_owner:Vcs.User_handle.t option -> Processed.t Or_error.t
end = struct
  (* various utilities -- mostly attempting to make the code more readable *)
  let named_group name patt = String.concat [ "(?P<"; name; ">"; patt; ")" ]

  (* (?:re)? makes an optional group that can't be matched via the ~sub arguments to
     various re2 functions.  I don't know if this is any better than just (re)?, but it's
     certainly not worse. *)
  let with_flags flags patt = String.concat [ "(?"; flags; ":"; patt; ")" ]
  let protect patt = with_flags "" patt (* to avoid the usual stringy macro problems *)
  let optional patt = protect patt ^ "?"
  let any patt = protect patt ^ "*"
  let some patt = protect patt ^ "+"
  let seq patts = String.concat patts
  let alt patts = protect (String.concat ~sep:"|" patts)

  (* : and @ have other meanings in CR comments *)
  let word = "[^ \\t\\n:@]+"
  let whitespace = "\\s"
  let exactly patt = Regex.create_exn ("^" ^ patt ^ "$")

  let comment_regex =
    exactly
      (seq
         [ any whitespace
         ; optional (named_group "is_xcr" "X")
         ; "CR"
         ; optional
             (seq [ "[-v]"; named_group "due" (alt [ "\\d{6}"; "soon"; "someday" ]) ])
         ; some whitespace
         ; named_group "from_user" word
         ; optional
             (seq [ some whitespace; "for"; some whitespace; named_group "for" word ])
         ; any whitespace
         ; ":"
         ; with_flags "s" ".*" (* the "s" flag makes "." match newlines *)
         ])
  ;;

  let process raw ~file_owner =
    try
      let content = raw.Raw.content in
      match Regex.get_matches_exn ~max:1 comment_regex content with
      | [] -> Or_error.error "Invalid CR comment" content String.sexp_of_t
      | m :: _ ->
        let get field_name = Regex.Match.get ~sub:(`Name field_name) m in
        (match get "from_user" with
         | None -> Or_error.error "Couldn't parse username" content String.sexp_of_t
         | Some reported_by ->
           let unresolved_name string =
             match Vcs.User_handle.of_string string with
             | Ok n -> Some n
             | Error (`Msg _) -> None
           in
           let reported_by = unresolved_name reported_by in
           let is_xcr = Option.is_some (get "is_xcr") in
           let for_ = Option.bind (get "for") ~f:unresolved_name in
           let due =
             match get "due" with
             | None -> Ok Due.Now
             | Some "soon" -> Ok Due.Soon
             | Some "someday" -> Ok Due.Someday
             | Some _s -> (* dated CR -> CR-someday *) Ok Due.Someday
           in
           (match due with
            | Error _ as err -> err
            | Ok due ->
              let assignee =
                Processed.compute_assignee ~file_owner ~reported_by ~for_ ~due ~is_xcr
              in
              Ok { Processed.raw; reported_by; for_; due; is_xcr; assignee }))
    with
    | exn -> Or_error.error "could not process CR" (raw, exn) [%sexp_of: Raw.t * exn]
  ;;
end

module Crs = struct
  type nonrec t =
    { due_now : t list
    ; due_soon : Cr_soon.t list
    ; due_someday : t list
    }
end

let extract ~path ~file_contents ~file_owner =
  List.filter_map
    (Raw.With_file_positions.extract ~path ~file_contents ())
    ~f:(fun { cr = raw; _ } ->
      match Process.process raw ~file_owner with
      | Ok p -> Some (Processed p)
      | Error _ -> Some (Raw raw))
;;

let grep ~vcs ~repo_root ~below ~file_owner =
  let files_to_grep = Vcs.ls_files vcs ~repo_root ~below in
  let stdin =
    files_to_grep |> List.map ~f:Vcs.Path_in_repo.to_string |> String.concat ~sep:"\n"
  in
  let files_to_grep =
    let context =
      Shexp_process.Context.create ~cwd:(Path (Vcs.Repo_root.to_string repo_root)) ()
    in
    let process =
      Shexp_process.pipe
        (Shexp_process.echo stdin)
        (Shexp_process.capture
           [ Stdout ]
           (Shexp_process.call_exit_code
              [ "xargs"
              ; "-r"
              ; "-d"
              ; "\n"
              ; "grep"
              ; "--no-messages"
              ; "-E"
              ; "-l"
              ; "--binary-files=without-match"
              ; cr_pattern_egrep
              ]))
    in
    let exit_code, stdout = Shexp_process.eval ~context process in
    match exit_code with
    | 0 | 123 -> stdout |> String.split_lines |> List.map ~f:Vcs.Path_in_repo.v
    | _ -> raise_s [%sexp "xargs process failed", { exit_code : int }]
  in
  let all_due_now = ref [] in
  let all_due_soon = ref [] in
  let all_due_someday = ref [] in
  let () =
    List.iter files_to_grep ~f:(fun path_in_repo ->
      let file_contents =
        In_channel.read_all
          (Vcs.Repo_root.append repo_root path_in_repo |> Absolute_path.to_string)
      in
      let file_owner =
        match file_owner path_in_repo with
        | Error _ -> None
        | Ok user -> Some user
      in
      List.iter (extract ~path:path_in_repo ~file_contents ~file_owner) ~f:(fun t ->
        match work_on t with
        | Someday -> all_due_someday := t :: !all_due_someday
        | Now -> all_due_now := t :: !all_due_now
        | Soon ->
          (match Cr_soon.create ~cr_comment:t with
           | Error _ -> all_due_now := t :: !all_due_now
           | Ok cr_soon -> all_due_soon := cr_soon :: !all_due_soon)))
  in
  { Crs.due_now = !all_due_now; due_soon = !all_due_soon; due_someday = !all_due_someday }
;;
