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

module Re_helper = struct
  type t =
    { re : Re.re
    ; status : int
    ; qualifier : int
    ; reporter : int
    ; recipient : int
    }
end

let make_re_helper () =
  let status_g = "status" in
  let qualifier_g = "qualifier" in
  let reporter_g = "reporter" in
  let recipient_g = "recipient" in
  let re =
    Re.(
      whole_string
        (seq
           [ rep whitespace
           ; group ~name:status_g (seq [ opt (char 'X'); str "CR" ])
           ; opt
               (seq
                  [ char '-'
                  ; group
                      ~name:qualifier_g
                      (alt [ repn digit 6 (Some 6); str "soon"; str "someday" ])
                  ])
           ; rep1 whitespace
           ; group ~name:reporter_g (rep1 word_t)
           ; opt
               (seq
                  [ rep1 whitespace
                  ; str "for"
                  ; rep1 whitespace
                  ; group ~name:recipient_g (rep1 word_t)
                  ])
           ; rep whitespace
           ; char ':'
           ; rep any
           ]))
    |> Re.compile
  in
  let groups = Re.group_names re |> Map.of_alist_exn (module String) in
  let find_group ~name = Map.find_exn groups name in
  { Re_helper.re
  ; status = find_group ~name:status_g
  ; qualifier = find_group ~name:qualifier_g
  ; reporter = find_group ~name:reporter_g
  ; recipient = find_group ~name:recipient_g
  }
;;

let re_helper = lazy (make_re_helper ())

let parse ~file_cache ~content_start_offset ~content =
  let ( let* ) a f = Result.bind a ~f in
  try
    let re_helper = Lazy.force re_helper in
    let* m =
      match Re.exec_opt re_helper.re content with
      | None -> Error (Dyn.Tuple [ Dyn.string "Invalid CR comment"; Dyn.string content ])
      | Some m -> Ok m
    in
    let get index =
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
      match get re_helper.reporter with
      | None -> assert false (* Mandatory in the [regexp]. *)
      | Some (reporter, loc) -> { Loc.Txt.txt = Vcs.User_handle.v reporter; loc }
    in
    let status =
      match get re_helper.status with
      | None -> assert false (* Mandatory in the [regexp]. *)
      | Some (status, loc) ->
        let txt : Cr_comment.Status.t =
          match status with
          | "CR" -> CR
          | "XCR" -> XCR
          | _ -> assert false (* Cannot be parsed according to the [regexp]. *)
        in
        { Loc.Txt.txt; loc }
    in
    let recipient =
      Option.map (get re_helper.recipient) ~f:(fun (user, loc) ->
        { Loc.Txt.txt = Vcs.User_handle.v user; loc })
    in
    let qualifier =
      match get re_helper.qualifier with
      | None -> { Loc.Txt.txt = Cr_comment.Qualifier.None; loc = status.loc }
      | Some ("soon", loc) -> { Loc.Txt.txt = Cr_comment.Qualifier.Soon; loc }
      | Some ("someday", loc) -> { Loc.Txt.txt = Cr_comment.Qualifier.Someday; loc }
      | Some (_, loc) ->
        (* dated CR -> CR-someday *)
        { Loc.Txt.txt = Cr_comment.Qualifier.Someday; loc }
    in
    Ok (Cr_comment.Private.Header.create ~status ~qualifier ~reporter ~recipient)
  with
  | exn ->
    (* This catches e.g. other invalid inputs such as invalid user names. *)
    let exn =
      match exn with
      | Invalid_argument str -> Dyn.variant "Invalid_argument" [ Dyn.string str ]
      | Failure str -> Dyn.variant "Failure" [ Dyn.string str ]
      | _ -> Dyn.string (Stdlib.Printexc.to_string exn)
    in
    (Error (Dyn.Tuple [ Dyn.string "Could not process CR."; Dyn.string content; exn ])
    [@coverage off])
;;
