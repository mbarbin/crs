(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

let main =
  Command.group
    ~summary:"A tool for managing inline review comments embedded in source code."
    ~readme:(fun () ->
      "The primary goal of $(b,crs) is to make it easy to locate, parse, and manipulate \
       special inline review comments called 'CRs' (pronounced \"C\"-\"R\"-z), embedded \
       directly in source code.\n\n\
       This CLI aims to offer ergonomic helpers for tasks such as systematically \
       updating comments across multiple files, changing their priority, marking them as \
       resolved, modifying reporter or assignee information, and more.\n\n\
       Main commands include:\n\n\
       - $(b,grep): grep-search and print CRs found in the current repository.\n\n\
       - $(b,tools): a collection of more specific commands, for example to facilitate \
       the integration with other tools (editors, etc).\n\n\
       For more information, use the $(b,--help) flag on a subcommand.")
    [ "grep", Cmd__grep.main
    ; ( "tools"
      , Command.group
          ~summary:"Useful utils to integrate with other tools."
          [ ( "config"
            , Command.group
                ~summary:"Utils related to config files."
                [ "validate", Cmd__tools__config__validate.main ] )
          ; "crs-ignore", Cmd__tools__crs_ignore.main
          ; "emacs-grep", Cmd__tools__emacs_grep.main
          ; "enclosing-repo-info", Cmd__tools__enclosing_repo_info.main
          ; ( "github"
            , Command.group
                ~summary:"Utils related to GitHub."
                [ "annotate-crs", Cmd__tools__github__annotate_crs.main
                ; "summary-comment", Cmd__tools__github__summary_comment.main
                ] )
          ; ( "reviewdog"
            , Command.group
                ~summary:"Utils related to Reviewdog."
                [ "annotate-crs", Cmd__tools__reviewdog__annotate_crs.main ] )
          ] )
    ]
;;

module Private = struct
  let grep_cmd = Cmd__grep.main

  module Std = struct
    module Annotation = Annotation
    module Assignee = Assignee
    module Config = Config
    module Review_mode = Review_mode
    module Reviewdog_utils = Reviewdog_utils
    module Summary_table = Summary_table
  end
end

open struct
  (* In a next version we are going to use this dependency to create auto edit
     tooling. Think specialized code mods for CRs (edit priorities, bulk Xing,
     strip, etc.). Make the dep used in the meanwhile. *)
  open! File_rewriter
end
