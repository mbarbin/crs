(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

let extended_range ~original_contents ~(range : Loc.Range.t) =
  let len = String.length original_contents in
  (* Extend left: consume spaces and tabs backwards, stop at newline (not
     included) or non-whitespace (not included) or beginning of file. *)
  let start =
    let rec loop i =
      if i <= 0
      then 0
      else (
        match original_contents.[i - 1] with
        | ' ' | '\t' -> loop (i - 1)
        | _ -> i)
    in
    loop range.start
  in
  (* The range starts at a line boundary if we reached the beginning of the
     file or the character just before [start] is a newline. *)
  let at_line_start = start = 0 || Char.equal original_contents.[start - 1] '\n' in
  (* Extend right: consume spaces and tabs forwards. Only include a trailing
     newline if the left extension reached a line boundary — this avoids
     removing the line structure when the range follows code on the same
     line. *)
  let stop =
    let rec loop i =
      if i >= len
      then i
      else (
        match original_contents.[i] with
        | ' ' | '\t' -> loop (i + 1)
        | '\n' -> if at_line_start then i + 1 else i
        | _ -> i)
    in
    loop range.stop
  in
  (* When the range is surrounded by code on both sides (not at a line
     boundary), preserve a single space so that adjacent tokens remain
     properly separated (e.g. "let () = (* comment *) ()" becomes
     "let () = ()" rather than "let () =()"). *)
  let start =
    if
      (not at_line_start)
      && stop < len
      && (not (Char.equal original_contents.[stop] '\n'))
      && start < range.start
    then start + 1
    else start
  in
  { Loc.Range.start; stop }
;;

let test ~path ~file_contents:original_contents ~f =
  let file_contents =
    (* In this test we want to avoid test CRs to be mistaken for actual CRs,
       thus we perform some dynamic string substitutions. *)
    original_contents
    |> String.substr_replace_all ~pattern:"$CR" ~with_:"CR"
    |> String.substr_replace_all ~pattern:"$XCR" ~with_:"XCR"
    |> Vcs.File_contents.create
  in
  let crs = Crs_parser.parse_file ~path ~file_contents in
  let file_rewriter =
    File_rewriter.create
      ~path:(Vcs.Path_in_repo.to_fpath path)
      ~original_contents:(file_contents :> string)
  in
  f ~crs ~file_rewriter;
  let output =
    File_rewriter.contents file_rewriter
    |> String.substr_replace_all ~pattern:" CR" ~with_:" $CR"
    |> String.substr_replace_all ~pattern:" XCR" ~with_:" $XCR"
  in
  Myers.print_diff original_contents output ~context:3
;;
