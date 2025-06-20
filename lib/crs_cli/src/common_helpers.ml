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
    let+ select =
      Arg.flag
        [ Cr_comment.Filter.to_string filter
        ; Printf.sprintf "%c" (Cr_comment.Filter.shorthand filter)
        ]
        ~doc:
          (Printf.sprintf
             "Select only CRs of type %S"
             (Cr_comment.Filter.to_string filter))
    in
    if select then [ filter ] else []
  in
  let+ invalid = one Invalid
  and+ crs = one CRs
  and+ xcrs = one XCRs
  and+ now = one Now
  and+ soon = one Soon
  and+ someday = one Someday in
  let filters = List.concat [ invalid; crs; xcrs; now; soon; someday ] in
  match filters with
  | [] -> `Default
  | _ :: _ as filters -> `Supplied filters
;;
