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

let path = Vcs.Path_in_repo.v "my_file.ml"

module Getters = struct
  type t =
    { status : Cr_comment.Status.t Loc.Txt.t
    ; qualifier : string Loc.Txt.t option
    ; reporter : string Loc.Txt.t option
    ; for_or_to : string Loc.Txt.t option
    ; recipient : string Loc.Txt.t option
    ; contents : string Loc.Txt.t
    }

  let to_dyn { status; qualifier; reporter; for_or_to; recipient; contents } =
    Dyn.record
      [ "status", status |> Loc.Txt.to_dyn Cr_comment.Status.to_dyn
      ; "qualifier", qualifier |> Dyn.option (Loc.Txt.to_dyn Dyn.string)
      ; "reporter", reporter |> Dyn.option (Loc.Txt.to_dyn Dyn.string)
      ; "for_or_to", for_or_to |> Dyn.option (Loc.Txt.to_dyn Dyn.string)
      ; "recipient", recipient |> Dyn.option (Loc.Txt.to_dyn Dyn.string)
      ; "contents", contents |> Loc.Txt.to_dyn Dyn.string
      ]
  ;;

  let of_cr (cr : Invalid_cr.t) =
    { status = Invalid_cr.status cr
    ; qualifier = Invalid_cr.qualifier cr
    ; reporter = Invalid_cr.reporter cr
    ; for_or_to = Invalid_cr.for_or_to cr
    ; recipient = Invalid_cr.recipient cr
    ; contents = Invalid_cr.contents cr
    }
  ;;
end

let test file_contents =
  let file_contents =
    (* In this test we want to avoid test CRs to be mistaken for actual CRs,
       thus we perform some dynamic string substitutions. *)
    file_contents
    |> String.strip
    |> String.substr_replace_all ~pattern:"$CR" ~with_:"CR"
    |> String.substr_replace_all ~pattern:"$XCR" ~with_:"XCR"
    |> Vcs.File_contents.create
  in
  let file_cache =
    Loc.File_cache.create
      ~path:(Vcs.Path_in_repo.to_relative_path path :> Fpath.t)
      ~file_contents:(Vcs.File_contents.to_string file_contents)
  in
  let crs =
    Crs_parser.parse_file ~path ~file_contents
    |> Cr_comment.sort
    |> List.filter_map ~f:(fun cr ->
      match Cr_comment.header cr with
      | Ok _ -> None
      | Error _ ->
        (match
           Invalid_cr_parser.parse
             ~file_cache
             ~content_start_offset:(Cr_comment.content_start_offset cr)
             ~content:(Cr_comment.content cr)
         with
         | Not_a_cr -> assert false
         | Invalid_cr cr -> Some cr))
  in
  Ref.set_temporarily Loc.include_sexp_of_locs false ~f:(fun () ->
    List.iter crs ~f:(fun t ->
      print_endline "========================";
      let getters = Getters.of_cr t in
      print_dyn (Dyn.record [ "getters", getters |> Getters.to_dyn ]);
      ()))
;;

let%expect_test "not-a-cr" =
  let file_contents = "Hello World" in
  let file_cache =
    Loc.File_cache.create
      ~path:(Vcs.Path_in_repo.to_relative_path path :> Fpath.t)
      ~file_contents
  in
  (match
     Invalid_cr_parser.parse ~file_cache ~content_start_offset:0 ~content:file_contents
   with
   | Invalid_cr _ -> assert false
   | Not_a_cr -> ());
  [%expect {||}];
  ()
;;

let%expect_test "getters" =
  (* Not a CR. *)
  test
    {|
(* $CR *)
|};
  [%expect {||}];
  (* Valid CR. *)
  test
    {|
(* $CR user: This is a valid one. *)
|};
  [%expect {||}];
  (* Invalid CRs. *)
  test
    {|
(* $CR : Hello contents. *)
|};
  [%expect
    {|
    ========================
    { getters =
        { status = CR
        ; qualifier = None
        ; reporter = None
        ; for_or_to = None
        ; recipient = None
        ; contents = "Hello contents."
        }
    }
    |}];
  test
    {|
(* $CR user1 to user2: Hello contents. *)
|};
  [%expect
    {|
    ========================
    { getters =
        { status = CR
        ; qualifier = None
        ; reporter = Some "user1"
        ; for_or_to = Some "to"
        ; recipient = Some "user2"
        ; contents = "Hello contents."
        }
    }
    |}];
  test
    {|
(* $CR-user Hello contents. *)
|};
  [%expect
    {|
    ========================
    { getters =
        { status = CR
        ; qualifier = Some "user"
        ; reporter = Some "Hello"
        ; for_or_to = None
        ; recipient = None
        ; contents = "contents."
        }
    }
    |}];
  test
    {|
(* $XCR-user: Hello contents. *)
|};
  [%expect
    {|
    ========================
    { getters =
        { status = XCR
        ; qualifier = Some "user"
        ; reporter = None
        ; for_or_to = None
        ; recipient = None
        ; contents = "Hello contents."
        }
    }
    |}];
  (* Below we illustrate that the invalid CRs abstraction allows one to
     manipulate components from CRs even though they are invalid, which should
     be useful to implement tooling on top. For example below, we feature CRs
     with invalid user handle and/or invalid qualifiers (see the typo below
     when the user wrote "soneday" instead of "someday"). *)
  test
    {|
(* $CR-soneday user1 for user#2: Hello contents. *)
|};
  [%expect
    {|
    ========================
    { getters =
        { status = CR
        ; qualifier = Some "soneday"
        ; reporter = Some "user1"
        ; for_or_to = Some "for"
        ; recipient = Some "user#2"
        ; contents = "Hello contents."
        }
    }
    |}];
  (* Bot user handles like github-something[bot] are now valid and no longer
     appear in this invalid CRs test. See test__user_handle.ml for bot handle
     validation tests. *)
  test
    {|
(* $CR github-something[bot]: Feedback from automated workflow X. *)
|};
  [%expect {||}];
  ()
;;
