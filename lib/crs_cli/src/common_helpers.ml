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

let find_enclosing_repo ~from =
  let vcs_git = Volgo_git_unix.create () in
  match
    Vcs.find_enclosing_repo_root
      vcs_git
      ~from
      ~store:[ Fsegment.dot_git, `Git; Fsegment.dot_hg, `Hg ]
  with
  | Some ((`Git as vcs_kind), repo_root) ->
    { Enclosing_repo.vcs_kind; repo_root; vcs = (vcs_git :> Enclosing_repo.vcs) }
  | Some ((`Hg as vcs_kind), repo_root) ->
    let vcs_hg = Volgo_hg_unix.create () in
    { Enclosing_repo.vcs_kind; repo_root; vcs = (vcs_hg :> Enclosing_repo.vcs) }
  | None ->
    Err.raise
      Pp.O.
        [ Pp.text "Failed to locate enclosing repo root from '"
          ++ Pp_tty.path (module Absolute_path) from
          ++ Pp.text "'."
        ] [@coverage off]
;;

let relativize ~repo_root ~cwd ~path =
  let path = Absolute_path.relativize ~root:cwd path in
  match
    Absolute_path.chop_prefix path ~prefix:(repo_root |> Vcs.Repo_root.to_absolute_path)
  with
  | Some relative_path -> Vcs.Path_in_repo.of_relative_path relative_path
  | None ->
    Err.raise
      Pp.O.
        [ Pp.text "Path "
          ++ Pp_tty.path (module Absolute_path) path
          ++ Pp.text " is not in repo."
        ]
;;

let filters =
  let open Command.Std in
  let one filter =
    let filter_str = Cr_comment.Filter.to_string filter in
    let+ select =
      Arg.flag
        [ filter_str; Printf.sprintf "%c" (Cr_comment.Filter.shorthand filter) ]
        ~doc:
          (match filter with
           | All -> "Select all CRs types (this is the default)."
           | Invalid -> "Select only invalid CRs."
           | CRs -> "Select only CRs of type CR."
           | XCRs -> "Select only CRs of type XCR."
           | Now | Soon | Someday ->
             Printf.sprintf "Select only CRs to be worked on %s." filter_str)
    in
    if select then [ filter ] else []
  in
  let+ all = one All
  and+ invalid = one Invalid
  and+ crs = one CRs
  and+ xcrs = one XCRs
  and+ now = one Now
  and+ soon = one Soon
  and+ someday = one Someday in
  let filters = List.concat [ all; invalid; crs; xcrs; now; soon; someday ] in
  match filters with
  | [] -> `All
  | _ :: _ as filters -> `Only filters
;;

let with_user_mentions_arg =
  let open Command.Std in
  Arg.named_with_default
    [ "with-user-mentions" ]
    Param.bool
    ~default:false
    ~doc:
      "If true, prefix the assignee's login with '@' in annotation messages (e.g., \
       $(i,@assignee-login)), which may trigger a notification in some environments \
       (such as GitHub PR reviews). If false, the assignee's login is shown without the \
       '@', so no notification is triggered. Note: For a notification to be triggered, \
       the user must also be included in the configured user-mentions whitelist. This \
       flag only affects notification behavior, as the assignee's name is always \
       displayed."
;;
