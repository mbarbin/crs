(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

let test args =
  match
    let cmd =
      Command.make
        (Review_mode.arg ~emit_github_annotations:true)
        ~summary:"Return the args."
    in
    Cmdlang_stdlib_runner.eval cmd ~argv:(Array.of_list ("./main.exe" :: args))
  with
  | Ok a -> print_dyn (a |> Review_mode.to_dyn)
  | Error (`Help _ | `Bad _) -> assert false
;;

let%expect_test "arg" =
  Err.For_test.protect (fun () -> test []);
  [%expect {| Revision |}];
  Err.For_test.protect (fun () -> test [ "--pull-request-author=jdoe" ]);
  [%expect
    {|
    Error: [--pull-request-author] should not be set when review mode is
    [revision].
    [124]
    |}];
  Err.For_test.protect (fun () -> test [ "--review-mode=commit" ]);
  [%expect
    {|
    Warning: Parameter [commit] for [--review-mode] was renamed [revision].
    Please attend.
    ::warning title=crs::Parameter [commit] for [--review-mode] was renamed [revision].%0APlease attend.
    Revision
    |}];
  Err.For_test.protect (fun () -> test [ "--review-mode=revision" ]);
  [%expect {| Revision |}];
  Err.For_test.protect (fun () -> test [ "--review-mode=pull-request" ]);
  [%expect
    {|
    Error: Review mode [pull-request] requires [--pull-request-author].
    [124]
    |}];
  Err.For_test.protect (fun () ->
    test [ "--review-mode=pull-request"; "--pull-request-author=jdoe" ]);
  [%expect
    {|
    Warning: Review mode [pull-request] requires [--pull-request-base].
    It will become mandatory in the future, please attend.
    ::warning title=crs::Review mode [pull-request] requires [--pull-request-base].%0AIt will become mandatory in the future, please attend.
    Pull_request { author = "jdoe"; base = None }
    |}];
  let mock_rev_gen = Vcs.Mock_rev_gen.create ~name:"review" in
  let base = Vcs.Mock_rev_gen.next mock_rev_gen in
  Err.For_test.protect (fun () ->
    test
      [ "--review-mode=pull-request"
      ; "--pull-request-author=jdoe"
      ; "--pull-request-base=" ^ Vcs.Rev.to_string base
      ]);
  [%expect
    {|
    Pull_request
      { author = "jdoe"; base = Some "6c3e826c6e1da1d8975aaca8fbfbbaac6c3e826c" }
    |}];
  ()
;;
