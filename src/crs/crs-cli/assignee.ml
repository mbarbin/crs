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

module Raw_assignee = struct
  type t =
    | Not_due_now
    | Invalid
    | Recipient of Vcs.User_handle.t
    | Reporter of Vcs.User_handle.t
    | Unaddressed

  let compute ~cr ~config:_ =
    match Cr_comment.priority cr with
    | Soon | Someday -> Not_due_now
    | Now ->
      (match Cr_comment.header cr with
       | Error _ -> Invalid
       | Ok h ->
         (match Cr_comment.Header.status h with
          | XCR -> Reporter (Cr_comment.Header.reporter h)
          | CR ->
            (match Cr_comment.Header.recipient h with
             | Some user -> Recipient user
             | None -> Unaddressed)))
  ;;
end

module Reason = struct
  type t =
    | Not_due_now
    | Recipient
    | Reporter
    | Default_repo_owner
    | No_default_repo_owner
    | Pull_request_author

  let all =
    [ Not_due_now
    ; Recipient
    ; Reporter
    ; Default_repo_owner
    ; No_default_repo_owner
    ; Pull_request_author
    ]
  ;;

  let variant_constructor_name = function
    | Not_due_now -> "Not_due_now"
    | Recipient -> "Recipient"
    | Reporter -> "Reporter"
    | Default_repo_owner -> "Default_repo_owner"
    | No_default_repo_owner -> "No_default_repo_owner"
    | Pull_request_author -> "Pull_request_author"
  ;;

  let to_dyn t = Dyn.Variant (variant_constructor_name t, [])

  let to_string_hum = function
    | Not_due_now -> "CR not due now"
    | Recipient -> "CR recipient"
    | Reporter -> "CR reporter"
    | Default_repo_owner -> "default repo owner"
    | No_default_repo_owner -> "no default repo owner configured"
    | Pull_request_author -> "PR author"
  ;;
end

type t =
  { user : Vcs.User_handle.t option
  ; reason : Reason.t
  }

let to_dyn { user; reason } =
  Dyn.record
    [ "user", user |> Dyn.option (fun u -> Dyn.stringable (module Vcs.User_handle) u)
    ; "reason", reason |> Reason.to_dyn
    ]
;;

let of_raw
      ~(raw_assignee : Raw_assignee.t)
      ~(config : Config.t)
      ~(review_mode : Review_mode.t)
  =
  let default =
    match review_mode with
    | Pull_request { author; base = _ } ->
      { user = Some author; reason = Pull_request_author }
    | Revision ->
      (match Config.default_repo_owner config with
       | Some owner -> { user = Some owner; reason = Default_repo_owner }
       | None -> { user = None; reason = No_default_repo_owner })
  in
  match raw_assignee with
  | Not_due_now -> { user = None; reason = Not_due_now }
  | Invalid -> default
  | Recipient recipient -> { user = Some recipient; reason = Recipient }
  | Reporter reporter -> { user = Some reporter; reason = Reporter }
  | Unaddressed -> default
;;

let compute ~cr ~(config : Config.t) ~(review_mode : Review_mode.t) =
  let raw_assignee = Raw_assignee.compute ~cr ~config in
  of_raw ~raw_assignee ~config ~review_mode
;;
