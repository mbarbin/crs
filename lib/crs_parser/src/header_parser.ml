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
   * - Migrate to this file only the part that relates to the parsing of the 1st line.
   * - Remove dependency to [Core] - make small adjustments to use [Base] instead.
   * - Replace [Unresolved_name] by [Vcs.User_handle].
   * - Remove alternate names and aliases resolution.
   * - Remove support for in-file `Properties.
   * - Remove support for extra headers.
   * - Remove support for attributes.
   * - Remove assignee computation (left as external work).
   * - Replace [is_xcr] by a variant type [Status.t].
   * - Make [reporter] mandatory.
   * - Rename [Processed] to [Header].
   * - Remove support for 'v' separator in CR comment
   * - Include the leading '-' char in due's [Loc.t].
   * - Migrate from [Re2] to [ocaml-re].
*)

(* : and @ have other meanings in CR comments *)
let word_t =
  Re.compl [ Re.char ' '; Re.char '\t'; Re.char '\n'; Re.char ':'; Re.char '@' ]
;;

let whitespace = Re.alt [ Re.char ' '; Re.char '\n'; Re.char '\t' ]

let comment_regex =
  lazy
    (Re.(
       whole_string
         (seq
            [ rep whitespace
            ; group ~name:"status" (seq [ opt (char 'X'); str "CR" ])
            ; opt
                (seq
                   [ char '-'
                   ; group
                       ~name:"qualifier"
                       (alt [ repn digit 6 (Some 6); str "soon"; str "someday" ])
                   ])
            ; rep1 whitespace
            ; group ~name:"reporter" (rep1 word_t)
            ; opt
                (seq
                   [ rep1 whitespace
                   ; str "for"
                   ; rep1 whitespace
                   ; group ~name:"recipient" (rep1 word_t)
                   ])
            ; rep whitespace
            ; char ':'
            ; rep any
            ]))
     |> Re.compile)
;;

let parse ~file_cache ~content_start_offset ~content =
  let ( let* ) a f = Or_error.bind a ~f in
  try
    let comment_regex = Lazy.force comment_regex in
    let group_names = Re.group_names comment_regex in
    let* m =
      match Re.exec_opt comment_regex content with
      | None -> Or_error.error "Invalid CR comment" content String.sexp_of_t
      | Some m -> Or_error.return m
    in
    let get field_name =
      let index =
        match
          List.find group_names ~f:(fun (name, _) -> String.equal field_name name)
        with
        | Some (_, index) -> index
        | None ->
          failwith
            (Printf.sprintf "Invalid regexp group name %S" field_name) [@coverage off]
      in
      match Re.Group.get_opt m index with
      | None -> None
      | Some v ->
        let start, stop = Re.Group.offset m index in
        let loc =
          Loc.of_file_range
            ~file_cache
            ~range:
              { start = content_start_offset + start; stop = content_start_offset + stop }
        in
        Some (v, loc)
    in
    let reporter =
      match get "reporter" with
      | None -> assert false (* Mandatory in the [comment_regexp]. *)
      | Some (reporter, loc) -> { Loc.Txt.txt = Vcs.User_handle.v reporter; loc }
    in
    let status =
      match get "status" with
      | None -> assert false (* Mandatory in the [comment_regexp]. *)
      | Some (status, loc) ->
        let txt : Cr_comment.Status.t =
          match status with
          | "CR" -> CR
          | "XCR" -> XCR
          | _ -> assert false (* Cannot be parsed according to the regexp. *)
        in
        { Loc.Txt.txt; loc }
    in
    let recipient =
      Option.map (get "recipient") ~f:(fun (user, loc) ->
        { Loc.Txt.txt = Vcs.User_handle.v user; loc })
    in
    let qualifier =
      match get "qualifier" with
      | None -> { Loc.Txt.txt = Cr_comment.Qualifier.None; loc = status.loc }
      | Some ("soon", loc) -> { Loc.Txt.txt = Cr_comment.Qualifier.Soon; loc }
      | Some ("someday", loc) -> { Loc.Txt.txt = Cr_comment.Qualifier.Someday; loc }
      | Some (_, loc) ->
        (* dated CR -> CR-someday *)
        { Loc.Txt.txt = Cr_comment.Qualifier.Someday; loc }
    in
    Or_error.return
      (Cr_comment.Private.Header.create ~status ~qualifier ~reporter ~recipient)
  with
  | exn ->
    Or_error.error
      "could not process CR"
      (content, exn)
      [%sexp_of: string * exn] [@coverage off]
;;
