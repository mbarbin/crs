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
  Command.group
    ~summary:"A tool for managing code review comments embedded in source code."
    ~readme:(fun () ->
      {|
The primary goal of $(b,crs) is to make it easy to locate, parse, and manipulate special code review comments called 'CRs' (pronounced "C"-"R"-z), embedded directly in source code.

This CLI aims to offer ergonomic helpers for tasks such as systematically updating comments across multiple files, changing their priority, marking them as resolved, modifying reporter or assignee information, and more.

Main commands include:

- $(b,grep): grep-search and print CRs found in the current repository.

- $(b,tools): a collection of more specific commands, for example to facilitate the integration with other tools (editors, etc).

For more information, use the $(b,--help) flag on a subcommand.
|})
    [ "grep", Cmd__grep.main
    ; ( "tools"
      , Command.group
          ~summary:"Useful utils to integrate with other tools."
          [ "emacs-grep", Cmd__tools__emacs_grep.main
          ; "enclosing-repo-info", Cmd__tools__enclosing_repo_info.main
          ] )
    ]
;;

module Private = struct
  let grep_cmd = Cmd__grep.main
end
