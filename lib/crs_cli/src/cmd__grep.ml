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

let main =
  Command.make
    ~summary:"Grep for CRs in the tree"
    (let%map_open.Command below =
       Arg.named_opt
         [ "below" ]
         (Param.validated_string (module Fpath))
         ~docv:"PATH"
         ~doc:"Only grep below the supplied path."
     and sexp = Arg.flag [ "sexp" ] ~doc:"Print the CRs as sexps on stdout." in
     let vcs = Vcs_git_blocking.create () in
     let cwd = Unix.getcwd () |> Absolute_path.v in
     let repo_root = Common_helpers.find_enclosing_repo_root vcs ~from:cwd in
     let below =
       match below with
       | None -> Vcs.Path_in_repo.root
       | Some path -> Common_helpers.relativize ~repo_root ~cwd ~path
     in
     let crs = Crs_parser.grep ~vcs ~repo_root ~below in
     if sexp
     then
       List.iter crs ~f:(fun cr ->
         print_endline (Sexp.to_string_hum [%sexp (cr : Cr_comment.t)]))
     else print_endline "Table not implemented")
;;
