(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

let%expect_test "of_string" =
  let or_msg_to_dyn = function
    | Ok user -> Dyn.Variant ("Ok", [ Dyn.string (User_handle.to_string user) ])
    | Error (`Msg msg) ->
      Dyn.Variant ("Error", [ Dyn.Variant ("Msg", [ Dyn.string msg ]) ])
  in
  let test str = print_dyn (or_msg_to_dyn (User_handle.of_string str)) in
  test "user1";
  [%expect {| Ok "user1" |}];
  test "dependabot[bot]";
  [%expect {| Ok "dependabot[bot]" |}];
  test "github-actions[bot]";
  [%expect {| Ok "github-actions[bot]" |}];
  test "Heya_This.Is_valid2";
  [%expect {| Ok "Heya_This.Is_valid2" |}];
  test "user@invalid";
  [%expect {| Error (Msg "\"user@invalid\": invalid user_handle") |}];
  test "";
  [%expect {| Error (Msg "\"\": invalid user_handle") |}];
  ()
;;
