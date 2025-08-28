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

module Review_mode = Crs_cli.Private.Review_mode

let test args =
  match
    let cmd =
      Command.make
        (Review_mode.arg ~emit_github_annotations:true)
        ~summary:"Return the args."
    in
    Cmdlang_stdlib_runner.eval cmd ~argv:(Array.of_list ("./main.exe" :: args))
  with
  | Ok a -> print_s [%sexp (a : Review_mode.t)]
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
    (Pull_request (author jdoe) (base ()))
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
    {| (Pull_request (author jdoe) (base (6c3e826c6e1da1d8975aaca8fbfbbaac6c3e826c))) |}];
  ()
;;
