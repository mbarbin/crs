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
   * - Remove support for attributes.
   * - Remove assignee computation (left as external work).
   * - Replace [is_xcr] by a variant type [Kind.t].
   * - Make [reporter] mandatory.
   * - Refactor [Raw], make [t] a record with a processed part that may fail.
   * - Compute [digest_of_condensed_content] for all CR kinds.
   * - Rename [Processed] to [Header].
   * - Remove support for printing CRs without their content.
   * - Compute positions and offsets with [Loc].
   * - Some minor changes to the [reindented] content rendering.
   * - Add [comment_prefix].
*)

module Digest_hex = struct
  type t = string [@@deriving compare, equal, sexp_of]

  let to_string t = t
  let create str = str |> Stdlib.Digest.string |> Stdlib.Digest.to_hex
end

module Header = struct
  module T = struct
    [@@@coverage off]

    type t =
      { kind : Kind.t Loc.Txt.t
      ; qualifier : Qualifier.t Loc.Txt.t
      ; reporter : Vcs.User_handle.t Loc.Txt.t
      ; recipient : Vcs.User_handle.t Loc.Txt.t option
      }
    [@@deriving equal, sexp_of]
  end

  include T

  module With_loc = struct
    let reporter t = t.reporter
    let recipient t = t.recipient
    let kind t = t.kind
    let qualifier t = t.qualifier

    (* Deprecated. *)
    let reported_by = reporter
    let for_ = recipient
    let due = qualifier
  end

  let create ~kind ~qualifier ~reporter ~recipient =
    { kind; qualifier; reporter; recipient }
  ;;

  let reporter t = t.reporter.txt
  let recipient t = Option.map t.recipient ~f:Loc.Txt.txt
  let kind t = t.kind.txt
  let qualifier t = t.qualifier.txt

  (* Deprecated. *)
  let reported_by = reporter
  let for_ = recipient
end

module T = struct
  [@@@coverage off]

  type t =
    { path : Vcs.Path_in_repo.t
    ; whole_loc : Loc.t
    ; header : Header.t Or_error.t
    ; comment_prefix : string
    ; digest_of_condensed_content : Digest_hex.t
    ; content : string
    }
  [@@deriving equal, sexp_of]
end

include T

let path t = t.path
let content t = t.content
let whole_loc t = t.whole_loc
let header t = t.header

let create ~path ~whole_loc ~header ~comment_prefix ~digest_of_condensed_content ~content =
  { path; whole_loc; header; comment_prefix; digest_of_condensed_content; content }
;;

let digest_ignoring_minor_text_changes t = t.digest_of_condensed_content

module For_sorted_output : sig
  type nonrec t = t [@@deriving compare]
end = struct
  type nonrec t = t

  let compare t1 t2 =
    let c = Vcs.Path_in_repo.compare t1.path t2.path in
    if c <> 0
    then c
    else (
      let c = Int.compare (Loc.start_line t1.whole_loc) (Loc.start_line t2.whole_loc) in
      if c <> 0
      then c
      else Int.compare (Loc.start_offset t1.whole_loc) (Loc.start_offset t2.whole_loc))
  ;;
end

let reindented_content ?(new_line_prefix = "") t =
  let rstrip_prefix = String.rstrip new_line_prefix in
  let expect_comment_prefixed_lines =
    match t.comment_prefix with
    | "--" | ";" | ";;" | "//" | "#" | "##" -> true
    | _ -> false
  in
  let indent =
    let len =
      if expect_comment_prefixed_lines
      then (
        let start = Loc.start t.whole_loc in
        start.pos_cnum - start.pos_bol)
      else (
        match t.header with
        | Error _ ->
          let start = Loc.start t.whole_loc in
          (* The len of the indentation is a heuristic in this case. *)
          start.pos_cnum - start.pos_bol + String.length t.comment_prefix + 1
        | Ok h ->
          let start = Loc.start h.kind.loc in
          start.pos_cnum - start.pos_bol)
    in
    String.make len ' '
  in
  let str = t.content in
  let lines = String.split str ~on:'\n' in
  let lines =
    List.map lines ~f:(fun line ->
      let line = String.rstrip line in
      if String.is_empty line
      then rstrip_prefix
      else (
        let line =
          match String.chop_prefix line ~prefix:indent with
          | Some s -> s
          | None ->
            (* When the line have less indentation than expected, stripping it
               this way may end up breaking some vertical alignment present in
               the text. However the formatting of such CR would be flagged as
               invalid per some linting rule, so this is not a major problem. *)
            String.lstrip line
        in
        let line =
          match expect_comment_prefixed_lines with
          | false -> line
          | true ->
            (match String.chop_prefix line ~prefix:(t.comment_prefix ^ " ") with
             | Some s -> s
             | None ->
               (match String.chop_prefix line ~prefix:t.comment_prefix with
                | Some s -> s
                | None -> line))
        in
        new_line_prefix ^ line))
  in
  String.concat lines ~sep:"\n"
;;

let sort ts = List.sort ts ~compare:For_sorted_output.compare

let kind t =
  match t.header with
  | Error _ -> Kind.CR
  | Ok p -> Header.kind p
;;

let priority t : Priority.t =
  match t.header with
  | Error _ -> Now
  | Ok p ->
    (match Header.kind p with
     | XCR -> Now
     | CR -> Header.qualifier p |> Qualifier.priority)
;;

let to_string t =
  String.concat
    ~sep:"\n"
    [ Loc.to_string t.whole_loc; reindented_content t ~new_line_prefix:"  "; "" ]
;;

let output_one ~include_delim cr ~oc =
  let str = to_string cr in
  let nl = if include_delim then "\n" else "" in
  Out_channel.output_string oc (Printf.sprintf "%s%s" nl str)
;;

let output_list crs ~oc =
  let crs = sort crs in
  let include_delim = ref false in
  List.iter crs ~f:(fun cr ->
    output_one ~include_delim:!include_delim cr ~oc;
    include_delim := true)
;;

let print_list crs = output_list crs ~oc:Stdlib.stdout

module Private = struct
  module Header = Header

  let create = create
end

(* Deprecated *)

let work_on = priority
