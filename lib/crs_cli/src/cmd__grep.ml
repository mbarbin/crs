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
    ~summary:"Grep for CRs in the tree."
    (let%map_open.Command below =
       Arg.named_opt
         [ "below" ]
         (Param.validated_string (module Fpath))
         ~docv:"PATH"
         ~doc:"Only grep below the supplied path."
     and sexp = Arg.flag [ "sexp" ] ~doc:"Print the CRs as sexps on stdout."
     and summary =
       Arg.flag
         [ "summary" ]
         ~doc:
           "This flags causes the command to print CR counts in summary tables rather \
            than printing each CR individually. This is not compatible with $(b,sexp)."
     in
     let () =
       if sexp && summary
       then
         raise
           (Err.E
              (Err.create
                 ~exit_code:Err.Exit_code.cli_error
                 Pp.O.
                   [ Pp.text "The flags "
                     ++ Pp_tty.kwd (module String) "sexp"
                     ++ Pp.text " and "
                     ++ Pp_tty.kwd (module String) "summary"
                     ++ Pp.text " are exclusive."
                   ]
                 ~hints:[ Pp.text "Please choose one." ] [@coverage off]))
     in
     let vcs = Volgo_git_unix.create () in
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
     else if summary
     then (
       let by_type = Summary_table.By_type.make crs |> Summary_table.By_type.to_string in
       let summary = Summary_table.make crs |> Summary_table.to_string in
       let tables =
         List.filter [ by_type; summary ] ~f:(fun t -> not (String.is_empty t))
       in
       print_string (String.concat ~sep:"\n" tables))
     else Cr_comment.print_list crs)
;;
