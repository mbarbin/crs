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

open Dunolint.Config.V0.Std

let skip_paths =
  [ path (glob "_build/**")
  ; path (glob "_coverage/**")
  ; path (glob ".git/**")
  ; path (glob "doc/node_modules/**")
  ; path (glob "doc/build/**")
  ; path (glob "doc/.docusaurus/**")
  ]
;;

let rules = []

let config =
  let skip_subtree = cond [ or_ skip_paths, skip_subtree ] in
  Dunolint.Config.v0 (Dunolint.Config.V0.create ~skip_subtree ~rules ())
;;

let () =
  print_endline
    (Dunolint.Config.to_file_contents config ~generated_by:"dunolint-config/main.ml");
  ()
;;
