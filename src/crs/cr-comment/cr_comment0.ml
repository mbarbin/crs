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
 * - Replace [is_xcr] by a variant type [Status.t].
 * - Make [reporter] mandatory.
 * - Refactor [Raw], make [t] a record with a processed part that may fail.
 * - Compute [digest_of_condensed_content] for all CR kinds.
 * - Rename [Processed] to [Header].
 * - Remove support for printing CRs without their content.
 * - Compute positions and offsets with [Loc].
 * - Some minor changes to the [reindented] content rendering.
 * - Add [comment_prefix].
 * - Add [Dyn] to replace [Error].
 *)

module Digest_hex = struct
  type t = string

  let compare = String.compare
  let equal = String.equal
  let to_dyn = Dyn.string
  let to_string t = t
  let create str = str |> Digest.string |> Digest.to_hex
end

module Header = struct
  module T = struct
    [@@@coverage off]

    type t =
      { status : Status.t Loc.Txt.t
      ; qualifier : Qualifier.t Loc.Txt.t
      ; reporter : Vcs.User_handle.t Loc.Txt.t
      ; recipient : Vcs.User_handle.t Loc.Txt.t option
      }

    let equal t ({ status; qualifier; reporter; recipient } as t2) =
      phys_equal t t2
      || (Loc.Txt.equal Status.equal t.status status
          && Loc.Txt.equal Qualifier.equal t.qualifier qualifier
          && Loc.Txt.equal Vcs.User_handle.equal t.reporter reporter
          && Option.equal (Loc.Txt.equal Vcs.User_handle.equal) t.recipient recipient)
    ;;

    let to_dyn { status; qualifier; reporter; recipient } =
      let user_handle u = Dyn.stringable (module Vcs.User_handle) u in
      let loc_user_handle ul = Loc.Txt.to_dyn user_handle ul in
      Dyn.record
        [ "status", status |> Loc.Txt.to_dyn Status.to_dyn
        ; "qualifier", qualifier |> Loc.Txt.to_dyn Qualifier.to_dyn
        ; "reporter", reporter |> loc_user_handle
        ; "recipient", recipient |> Dyn.option loc_user_handle
        ]
    ;;
  end

  include T

  module With_loc = struct
    let reporter t = t.reporter
    let recipient t = t.recipient
    let status t = t.status
    let qualifier t = t.qualifier

    (* Deprecated. *)
    let reported_by = reporter
    let for_ = recipient
    let due = qualifier
    let kind = status
  end

  let create ~status ~qualifier ~reporter ~recipient =
    { status; qualifier; reporter; recipient }
  ;;

  let reporter t = t.reporter.txt
  let recipient t = Option.map t.recipient ~f:Loc.Txt.txt
  let status t = t.status.txt
  let qualifier t = t.qualifier.txt

  let priority t : Priority.t =
    match status t with
    | XCR -> Now
    | CR -> qualifier t |> Qualifier.priority
  ;;

  (* Deprecated. *)
  let reported_by = reporter
  let for_ = recipient
  let kind = status
end

let or_dyn to_dyn r =
  match r with
  | Ok ok -> Dyn.Variant ("Ok", [ to_dyn ok ])
  | Error dyn -> Dyn.Variant ("Error", [ dyn ])
;;

module T = struct
  [@@@coverage off]

  type t =
    { path : Vcs.Path_in_repo.t
    ; whole_loc : Loc.t
    ; content_start_offset : int
    ; header : (Header.t, Dyn.t) Result.t
    ; comment_prefix : string
    ; digest_of_condensed_content : Digest_hex.t
    ; content : string
    }

  let equal
        t
        ({ path
         ; whole_loc
         ; content_start_offset
         ; header
         ; comment_prefix
         ; digest_of_condensed_content
         ; content
         } as t2)
    =
    phys_equal t t2
    || (Vcs.Path_in_repo.equal t.path path
        && Digest_hex.equal t.digest_of_condensed_content digest_of_condensed_content
        && Loc.equal t.whole_loc whole_loc
        && Int.equal t.content_start_offset content_start_offset
        && Result.equal ~ok:Header.equal ~error:Dyn.equal t.header header
        && String.equal t.comment_prefix comment_prefix
        && String.equal t.content content)
  ;;

  let to_dyn
        { path : Vcs.Path_in_repo.t
        ; whole_loc : Loc.t
        ; content_start_offset : int
        ; header : (Header.t, Dyn.t) Result.t
        ; comment_prefix : string
        ; digest_of_condensed_content : Digest_hex.t
        ; content : string
        }
    =
    Dyn.record
      [ "path", path |> Dyn.stringable (module Vcs.Path_in_repo)
      ; "whole_loc", whole_loc |> Loc.to_dyn
      ; "content_start_offset", content_start_offset |> Dyn.int
      ; "header", header |> or_dyn Header.to_dyn
      ; "comment_prefix", comment_prefix |> Dyn.string
      ; "digest_of_condensed_content", digest_of_condensed_content |> Digest_hex.to_dyn
      ; "content", content |> Dyn.string
      ]
  ;;
end

include T

let path t = t.path
let content t = t.content
let content_start_offset t = t.content_start_offset
let comment_prefix t = t.comment_prefix
let whole_loc t = t.whole_loc
let header t = t.header

let create
      ~path
      ~whole_loc
      ~content_start_offset
      ~header
      ~comment_prefix
      ~digest_of_condensed_content
      ~content
  =
  { path
  ; whole_loc
  ; content_start_offset
  ; header
  ; comment_prefix
  ; digest_of_condensed_content
  ; content
  }
;;

let digest_ignoring_minor_text_changes t = t.digest_of_condensed_content

module For_sorted_output : sig
  type nonrec t = t

  val compare : t -> t -> int
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
          let start = Loc.start h.status.loc in
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

let status t : Status.t =
  match t.header with
  | Error _ -> CR
  | Ok p -> Header.status p
;;

let priority t : Priority.t =
  match t.header with
  | Error _ -> Now
  | Ok p -> Header.priority p
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

let print_list crs = output_list crs ~oc:Out_channel.stdout

module Private = struct
  module Header = Header

  let create = create
end

(* Deprecated *)

let work_on = priority
let kind = status
