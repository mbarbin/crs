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
    ~summary:"Validate the supplied config file."
    ~readme:(fun () ->
      "You can use this command to validate that the supplied file is a valid config \
       file for $(b,crs).")
    (let open Command.Std in
     let+ path = Arg.pos ~pos:0 Param.file ~doc:"Config file to customize crs."
     and+ print = Arg.flag [ "print" ] ~doc:"Print the parsed config as a S-expression."
     and+ print_gh_annotation_warnings =
       Arg.named_with_default
         [ "with-github-annotations-warnings" ]
         Param.bool
         ~default:false
         ~doc:
           "Optionally print GitHub Annotations Warnings to highlight deprecated \
            constructs, in addition to regular warning printed to stderr."
     in
     let config = Config.load_exn ~path:(Fpath.v path) ~print_gh_annotation_warnings in
     if print then print_s [%sexp (config : Config.t)])
;;
