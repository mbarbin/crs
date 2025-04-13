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
   * - Remove support for attributes.
   * - Remove assignee computation (left as external work).
   * - Replace [is_xcr] by a variant type [Kind.t].
   * - Make [reported_by] mandatory.
   * - Refactor [Raw], make [t] a record with a processed part that may fail.
   * - Compute [digest_of_condensed_content] for all CR kinds.
   * - Remove special type for cr soons. Return all CRs parsed.
   * - Rename [Processed] to [Header].
   * - Remove support for printing crs without their content.
   * - Compute positions and offsets with [Loc].
*)

module Digest_hex = struct
  type t = string [@@deriving compare, equal, sexp_of]

  let to_string t = t
  let create str = str |> Stdlib.Digest.string |> Stdlib.Digest.to_hex
end

module Kind = struct
  type t =
    | CR
    | XCR
  [@@deriving compare, equal, sexp_of]
end

module Due = struct
  type t =
    | Now
    | Soon
    | Someday
  [@@deriving compare, equal, sexp_of]
end

module Header = struct
  type t =
    { reported_by : Vcs.User_handle.t
    ; for_ : Vcs.User_handle.t option
    ; kind : Kind.t
    ; due : Due.t
    }
  [@@deriving equal, sexp_of]

  let create ~reported_by ~for_ ~kind ~due = { reported_by; for_; kind; due }
  let reported_by t = t.reported_by
  let for_ t = t.for_
  let kind t = t.kind
  let due t = t.due
end

(* [content] is the text of the CR with comment markers removed from
   the beginning and end (if applicable).

   The [whole_loc] is suitable for removal of the entire CR comment.
   It includes the comments boundaries from [path] as well. *)

type t =
  { path : Vcs.Path_in_repo.t
  ; content : string
  ; whole_loc : Loc.t
  ; header : Header.t Or_error.t
  ; digest_of_condensed_content : Digest_hex.t
  }
[@@deriving equal, sexp_of]

let path t = t.path
let content t = t.content
let whole_loc t = t.whole_loc
let header t = t.header

let create ~path ~content ~whole_loc ~header ~digest_of_condensed_content =
  { path; content; whole_loc; header; digest_of_condensed_content }
;;

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

let reindented_content t =
  let start = Loc.start t.whole_loc in
  let indent = String.make (start.pos_cnum - start.pos_bol + 2) ' ' in
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

let sort ts = List.sort ts ~compare:For_sorted_output.compare

let due t =
  match t.header with
  | Error _ -> Due.Now
  | Ok p -> p.due
;;

let kind t =
  match t.header with
  | Error _ -> Kind.CR
  | Ok p -> p.kind
;;

let work_on t : Due.t =
  match t.header with
  | Error _ -> Now
  | Ok p ->
    (match p.kind with
     | XCR -> Now
     | CR -> p.due)
;;

let to_string t =
  String.concat ~sep:"\n" [ Loc.to_string t.whole_loc; reindented_content t; "" ]
;;

let print ~include_delim cr =
  let str = to_string cr in
  let nl = if include_delim then "\n" else "" in
  print_string (Printf.sprintf "%s%s" nl str)
;;

let print_list ~crs =
  let crs = sort crs in
  let include_delim = ref false in
  List.iter crs ~f:(fun cr ->
    print ~include_delim:!include_delim cr;
    include_delim := true)
;;

module Private = struct
  module Header = Header

  let create = create
end
