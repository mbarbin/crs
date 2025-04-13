(********************************************************************************)
(*  crs - A tool to manipulate code review comments embedded in source code     *)
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
   * - Replace [is_xcr] by a variant type [Kind.t].
   * - Make [reported_by] mandatory.
   * - Rename [Processed] to [Header].
*)

module Regex = Re2

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

let parse ~file_cache:_ ~content_start_offset:_ ~content =
  try
    match Regex.get_matches_exn ~max:1 comment_regex content with
    | [] -> Or_error.error "Invalid CR comment" content String.sexp_of_t
    | m :: _ ->
      let get field_name = Regex.Match.get ~sub:(`Name field_name) m in
      (match get "from_user" with
       | None -> Or_error.error "Couldn't parse username" content String.sexp_of_t
       | Some reported_by ->
         let reported_by = Vcs.User_handle.v reported_by in
         let kind =
           match Option.is_some (get "is_xcr") with
           | true -> Cr_comment.Kind.XCR
           | false -> Cr_comment.Kind.CR
         in
         let for_ = Option.map (get "for") ~f:Vcs.User_handle.v in
         let due =
           match get "due" with
           | None -> Ok Cr_comment.Due.Now
           | Some "soon" -> Ok Cr_comment.Due.Soon
           | Some "someday" -> Ok Cr_comment.Due.Someday
           | Some _s -> (* dated CR -> CR-someday *) Ok Cr_comment.Due.Someday
         in
         (match due with
          | Error _ as err -> err
          | Ok due -> Ok (Cr_comment.Private.Header.create ~reported_by ~for_ ~kind ~due)))
  with
  | exn -> Or_error.error "could not process CR" (content, exn) [%sexp_of: string * exn]
;;
