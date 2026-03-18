(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

let pp_to_string pp =
  let buffer = Buffer.create 23 in
  let formatter = Format.formatter_of_buffer buffer in
  Format.fprintf formatter "%a%!" Pp.to_fmt pp;
  let contents =
    Buffer.contents buffer
    |> String.split_lines
    |> List.map ~f:(fun s -> String.rstrip s ^ "\n")
    |> String.concat ~sep:""
  in
  contents
;;

let emit_github_annotation ~severity ~loc ~messages ~hints =
  let message_text = String.concat ~sep:"" (List.map messages ~f:pp_to_string) in
  let hints_text =
    match hints with
    | None -> ""
    | Some hints -> "Hints: " ^ String.concat ~sep:" " (List.map hints ~f:pp_to_string)
  in
  let github_annotation =
    Github_annotation.create
      ~loc:(Option.value loc ~default:Loc.none)
      ~severity
      ~title:"crs"
      ~message:(String.strip (message_text ^ hints_text))
  in
  prerr_endline (Github_annotation.to_string github_annotation)
;;

let warning ?loc ~emit_github_annotations ?hints messages =
  Err.warning ?loc ?hints messages;
  if emit_github_annotations
  then emit_github_annotation ~severity:Warning ~loc ~messages ~hints
;;

let error ?loc ~emit_github_annotations ?hints messages =
  Err.error ?loc ?hints messages;
  if emit_github_annotations
  then emit_github_annotation ~severity:Error ~loc ~messages ~hints
;;
