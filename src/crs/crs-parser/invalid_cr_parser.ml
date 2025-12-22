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
    ; for_or_to : int
    ; recipient : int
    ; contents : int
    }
end

module Group_map = Map.Make (String)

let make_re_helper () =
  let status_g = "status" in
  let qualifier_g = "qualifier" in
  let reporter_g = "reporter" in
  let for_or_to_g = "for_or_to" in
  let recipient_g = "recipient" in
  let contents_g = "contents" in
  let re =
    Re.(
      whole_string
        (seq
           [ rep whitespace
           ; group ~name:status_g (seq [ opt (char 'X'); str "CR" ])
           ; opt (seq [ char '-'; group ~name:qualifier_g (rep1 word_t) ])
           ; rep whitespace
           ; opt (group ~name:reporter_g (rep1 word_t))
           ; opt
               (seq
                  [ rep whitespace
                  ; group ~name:for_or_to_g (alt [ str "for"; str "to" ])
                  ; rep1 whitespace
                  ; group ~name:recipient_g (rep1 word_t)
                  ])
           ; rep whitespace
           ; opt (char ':')
           ; group ~name:contents_g (rep any)
           ]))
    |> Re.compile
  in
  let groups = Re.group_names re |> List.to_seq |> Group_map.of_seq in
  let find_group ~name = Group_map.find name groups in
  { Re_helper.re
  ; status = find_group ~name:status_g
  ; qualifier = find_group ~name:qualifier_g
  ; reporter = find_group ~name:reporter_g
  ; for_or_to = find_group ~name:for_or_to_g
  ; recipient = find_group ~name:recipient_g
  ; contents = find_group ~name:contents_g
  }
;;

let re_helper = lazy (make_re_helper ())

module Invalid_cr = struct
  type t =
    { status : Cr_comment.Status.t Loc.Txt.t
    ; qualifier : string Loc.Txt.t option
    ; reporter : string Loc.Txt.t option
    ; for_or_to : string Loc.Txt.t option
    ; recipient : string Loc.Txt.t option
    ; contents : string Loc.Txt.t
    }

  let status t = t.status
  let qualifier t = t.qualifier
  let reporter t = t.reporter
  let for_or_to t = t.for_or_to
  let recipient t = t.recipient
  let contents t = t.contents
end

module Maybe_invalid_cr = struct
  type t =
    | Invalid_cr of Invalid_cr.t
    | Not_a_cr
end

let parse ~file_cache ~content_start_offset ~content =
  let re_helper = Lazy.force re_helper in
  match Re.exec_opt re_helper.re content with
  | None -> Maybe_invalid_cr.Not_a_cr
  | Some m ->
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
      | None -> None
      | Some (reporter, loc) -> Some { Loc.Txt.txt = reporter; loc }
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
    let for_or_to =
      Option.map (get re_helper.for_or_to) ~f:(fun (user, loc) ->
        { Loc.Txt.txt = user; loc })
    in
    let recipient =
      Option.map (get re_helper.recipient) ~f:(fun (user, loc) ->
        { Loc.Txt.txt = user; loc })
    in
    let qualifier =
      match get re_helper.qualifier with
      | None -> None
      | Some (txt, loc) -> Some { Loc.Txt.txt; loc }
    in
    let contents =
      match get re_helper.contents with
      | None -> assert false (* Mandatory in the [regexp]. *)
      | Some (contents, loc) -> { Loc.Txt.txt = String.strip contents; loc }
    in
    if String.is_empty contents.txt
    then Maybe_invalid_cr.Not_a_cr
    else
      Maybe_invalid_cr.Invalid_cr
        { status; qualifier; reporter; for_or_to; recipient; contents }
;;
