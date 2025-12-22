(****************************************************************************)
(*  ocaml-reviewdog - A reviewdog diagnostics json serializer for OCaml     *)
(*  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                            *)
(****************************************************************************)

type t =
  { message : string
  ; location : Location.t
  ; severity : Severity.t option
  ; source : Source.t option
  ; code : Code.t option
  ; suggestions : Suggestion.t list
  ; original_output : string option
  ; related_locations : Related_location.t list
  }

let to_json
      { message
      ; location
      ; severity
      ; source
      ; code
      ; suggestions
      ; original_output
      ; related_locations
      }
  : Yojson.Basic.t
  =
  `Assoc
    (List.concat
       [ [ "message", `String message ]
       ; [ "location", Location.to_json location ]
       ; (match severity with
          | None -> []
          | Some s -> [ "severity", Severity.to_json s ])
       ; (match source with
          | None -> []
          | Some s -> [ "source", Source.to_json s ])
       ; (match code with
          | None -> []
          | Some c -> [ "code", Code.to_json c ])
       ; (match suggestions with
          | [] -> []
          | _ -> [ "suggestions", `List (List.map Suggestion.to_json suggestions) ])
       ; (match original_output with
          | None -> []
          | Some o -> [ "originalOutput", `String o ])
       ; (match related_locations with
          | [] -> []
          | _ ->
            [ ( "relatedLocations"
              , `List (List.map Related_location.to_json related_locations) )
            ])
       ])
;;
