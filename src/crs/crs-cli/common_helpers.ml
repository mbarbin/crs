(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

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
       the user must also be included in the configured user-mentions allowlist. This \
       flag only affects notification behavior, as the assignee's name is always \
       displayed."
;;

let emit_github_annotations_arg ~default =
  let open Command.Std in
  Arg.named_with_default
    [ "emit-github-annotations"; "with-github-annotations-warnings" ]
    Param.bool
    ~default
    ~doc:
      "Optionally emit GitHub Annotations on $(b,stderr) to highlight issues (such as \
       deprecated constructs, errors, etc.) in addition to regular errors and warnings.\n\n\
       This may be convenient when running jobs from within GitHub Actions to increase \
       the chance of detecting these issues when inspecting the jobs summary pages.\n\n\
       The $(i,--with-github-annotations-warnings) alias is deprecated and will be \
       removed in a future release. Please update."
;;
