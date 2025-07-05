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

module Severity = struct
  type t = Config.Annotation_severity.t =
    | Error
    | Warning
    | Info
  [@@deriving enumerate, sexp_of]

  let to_string t =
    match sexp_of_t t with
    | Atom s -> s
    | List _ -> assert false
  ;;

  let to_github : t -> Github_annotation.Severity.t = function
    | Error -> Error
    | Warning -> Warning
    | Info -> Notice
  ;;

  let to_reviewdog : t -> Reviewdog.Severity.t = function
    | Error -> Error
    | Warning -> Warning
    | Info -> Info
  ;;
end

type t =
  { cr : Cr_comment.t
  ; severity : Severity.t
  ; assignee : Assignee.t
  ; with_user_mention : bool
  ; title : string
  ; message : string
  }
[@@deriving sexp_of]

let message t = t.message
let severity t = t.severity
let assignee t = t.assignee
let with_user_mention t = t.with_user_mention

let write_username ~user ~with_user_mention =
  (if with_user_mention then "@" else "") ^ Vcs.User_handle.to_string user
;;

let of_cr ~cr ~(config : Config.t) ~review_mode ~with_user_mentions =
  match Cr_comment.priority cr with
  | Soon | Someday -> None
  | Now ->
    let header = Cr_comment.header cr in
    let severity : Severity.t =
      match header with
      | Error _ -> Option.value config.invalid_crs_annotation_severity ~default:Warning
      | Ok _ -> Option.value config.crs_due_now_annotation_severity ~default:Info
    in
    let title =
      match header with
      | Error _ -> "Invalid CR"
      | Ok h -> Cr_comment.Status.to_string (Cr_comment.Header.status h)
    in
    let assignee = Assignee.compute ~cr ~config ~review_mode in
    let with_user_mention =
      match with_user_mentions with
      | false -> false
      | true ->
        (match assignee.user with
         | None -> false
         | Some user ->
           (match config.user_mentions_whitelist with
            | None -> false
            | Some list -> List.mem list user ~equal:Vcs.User_handle.equal))
    in
    let message =
      String.concat
        ~sep:" "
        [ "This"
        ; (match header with
           | Error _ -> "invalid CR"
           | Ok h -> Cr_comment.Status.to_string (Cr_comment.Header.status h))
        ; "is"
        ; (match assignee.user with
           | None -> "unassigned"
           | Some user ->
             Printf.sprintf "assigned to %s" (write_username ~user ~with_user_mention))
        ; Printf.sprintf "(%s)." (Assignee.Reason.to_string_hum assignee.reason)
        ]
    in
    Some { cr; severity; assignee; with_user_mention; title; message }
;;

let to_github_annotation t : Github_annotation.t =
  Github_annotation.create
    ~loc:(Cr_comment.whole_loc t.cr)
    ~severity:(Severity.to_github t.severity)
    ~title:t.title
    ~message:t.message
;;

let to_reviewdog_diagnostic t : Reviewdog.Diagnostic.t =
  { Reviewdog.Diagnostic.message = t.message
  ; location = Cr_comment.whole_loc t.cr |> Reviewdog_utils.make_location
  ; severity = Some (Severity.to_reviewdog t.severity)
  ; source = None
  ; code = None
  ; suggestions = None
  ; original_output = Some (Cr_comment.reindented_content t.cr)
  ; related_locations = None
  }
;;
