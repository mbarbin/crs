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

module Crs_ignore = Crs_parser.Private.Crs_ignore

let path = Vcs.Path_in_repo.v ".crs-ignore"

(* At first we have a few characterization tests related to the handling of
   parent paths, whose behavior is relied on in crs. *)

let%expect_test "relative parent is dir_path" =
  let p = Relative_path.v "a/b" in
  let parent = Relative_path.parent p |> Option.value_exn ~here:[%here] in
  require [%here] (Relative_path.is_dir_path parent);
  print_s [%sexp (parent : Relative_path.t)];
  [%expect {| a/ |}];
  ()
;;

let%expect_test "absolute parent is dir_path" =
  let p = Absolute_path.v "/a/b" in
  let parent = Absolute_path.parent p |> Option.value_exn ~here:[%here] in
  require [%here] (Absolute_path.is_dir_path parent);
  print_s [%sexp (parent : Absolute_path.t)];
  [%expect {| /a/ |}];
  ()
;;

let%expect_test "parent of dir_path" =
  let p = Relative_path.v "a/b/" in
  let parent = Relative_path.parent p |> Option.value_exn ~here:[%here] in
  require [%here] (Relative_path.is_dir_path parent);
  print_s [%sexp (parent : Relative_path.t)];
  [%expect {| a/ |}];
  ()
;;

let%expect_test "parent of relative_path" =
  let test p = print_s [%sexp (Relative_path.parent p : Relative_path.t option)] in
  test (Relative_path.v "a");
  [%expect {| (./) |}];
  test (Relative_path.v "a/b");
  [%expect {| (a/) |}];
  test (Relative_path.v "a/");
  [%expect {| (./) |}];
  test (Relative_path.v "a/b/");
  [%expect {| (a/) |}];
  test Relative_path.empty;
  [%expect {| (./../) |}];
  ()
;;

let%expect_test "relative empty is dir_path" =
  let parent = Relative_path.empty in
  require [%here] (Relative_path.is_dir_path parent);
  print_s [%sexp (parent : Relative_path.t)];
  [%expect {| ./ |}];
  ()
;;

let%expect_test "relative empty chop_prefix" =
  let suffix =
    Relative_path.chop_prefix
      ~prefix:Relative_path.empty
      (Vcs.Path_in_repo.to_relative_path path)
  in
  (* mbarbin: At the moment this doesn't work. I think of this as a bug of
     [Relative_path.chop_prefix], or at least this is not a behavior I intended.
     I will consider fixing this upstream and reconsider the test here.
     Currently we leave it as monitoring the current behavior for reference. *)
  require [%here] (Option.is_none suffix);
  print_s [%sexp { suffix : Relative_path.t option }];
  [%expect {| ((suffix ())) |}];
  ()
;;

let better_chop_prefix ~prefix path =
  if Relative_path.equal prefix Relative_path.empty
  then Some path
  else Relative_path.chop_prefix ~prefix path
;;

let%expect_test "better_chop_prefix" =
  let suffix =
    better_chop_prefix
      ~prefix:Relative_path.empty
      (Vcs.Path_in_repo.to_relative_path path)
  in
  require [%here] (Option.is_some suffix);
  print_s [%sexp { suffix : Relative_path.t option }];
  [%expect {| ((suffix (.crs-ignore))) |}];
  let suffix =
    better_chop_prefix ~prefix:(Relative_path.v "./a/") (Relative_path.v "a/b")
  in
  require [%here] (Option.is_some suffix);
  print_s [%sexp { suffix : Relative_path.t option }];
  [%expect {| ((suffix (b))) |}];
  let suffix =
    better_chop_prefix ~prefix:(Relative_path.v "./a") (Relative_path.v "a/b")
  in
  require [%here] (Option.is_some suffix);
  print_s [%sexp { suffix : Relative_path.t option }];
  [%expect {| ((suffix (b))) |}];
  ()
;;

let%expect_test "absolute root chop_prefix" =
  let suffix =
    Absolute_path.chop_prefix ~prefix:Absolute_path.root (Absolute_path.v "/a")
  in
  require [%here] (Option.is_some suffix);
  print_s [%sexp { suffix : Relative_path.t option }];
  [%expect {| ((suffix (a))) |}];
  let suffix =
    Absolute_path.chop_prefix ~prefix:(Absolute_path.v "/a/") (Absolute_path.v "/a/b")
  in
  require [%here] (Option.is_some suffix);
  print_s [%sexp { suffix : Relative_path.t option }];
  [%expect {| ((suffix (b))) |}];
  let suffix =
    Absolute_path.chop_prefix ~prefix:(Absolute_path.v "/a") (Absolute_path.v "/a/b")
  in
  require [%here] (Option.is_some suffix);
  print_s [%sexp { suffix : Relative_path.t option }];
  [%expect {| ((suffix (b))) |}];
  ()
;;

let%expect_test "is_file_ignored" =
  let test rules ~path =
    print_s [%sexp (Crs_ignore.Rules.is_file_ignored rules ~path : bool)]
  in
  let rules file_contents =
    let file =
      Crs_ignore.Private.File.parse_exn
        ~repo_root:(Vcs.Repo_root.v "/path/to/repo")
        ~path
        ~file_contents:(Vcs.File_contents.create file_contents)
        ~invalid_patterns_are_errors:true
        ~emit_github_annotations:false
    in
    Crs_ignore.Rules.create [ file ]
  in
  let r1 =
    rules
      {|
# This is a comment
README.md # Inline comment
subdir/*
vendor/**
foo/test_*.ml
|}
  in
  test r1 ~path:(Vcs.Path_in_repo.v "README.md");
  [%expect {| true |}];
  test r1 ~path:(Vcs.Path_in_repo.v "foo.ml");
  [%expect {| false |}];
  test r1 ~path:(Vcs.Path_in_repo.v "subdir/README.md");
  [%expect {| true |}];
  test r1 ~path:(Vcs.Path_in_repo.v "subdir/foo/foo.ml");
  [%expect {| false |}];
  test r1 ~path:(Vcs.Path_in_repo.v "vendor/README.md");
  [%expect {| true |}];
  test r1 ~path:(Vcs.Path_in_repo.v "vendor/foo/foo.ml");
  [%expect {| true |}];
  test r1 ~path:(Vcs.Path_in_repo.v "foo/test_foo.ml");
  [%expect {| true |}];
  test r1 ~path:(Vcs.Path_in_repo.v "foo/bar.ml");
  [%expect {| false |}];
  ()
;;
