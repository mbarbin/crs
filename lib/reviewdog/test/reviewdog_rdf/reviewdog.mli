(** Code for reviewdog.proto *)

(* generated from "reviewdog.proto", do not edit *)

(** {2 Types} *)

type position = private
  { mutable _presence : Pbrt.Bitfield.t (** presence for 2 fields *)
  ; mutable line : int32
  ; mutable column : int32
  }

type range = private
  { mutable start : position option
  ; mutable end_ : position option
  }

type location = private
  { mutable _presence : Pbrt.Bitfield.t (** presence for 1 fields *)
  ; mutable path : string
  ; mutable range : range option
  }

type severity =
  | Unknown_severity
  | Error
  | Warning
  | Info

type source = private
  { mutable _presence : Pbrt.Bitfield.t (** presence for 2 fields *)
  ; mutable name : string
  ; mutable url : string
  }

type code = private
  { mutable _presence : Pbrt.Bitfield.t (** presence for 2 fields *)
  ; mutable value : string
  ; mutable url : string
  }

type suggestion = private
  { mutable _presence : Pbrt.Bitfield.t (** presence for 1 fields *)
  ; mutable range : range option
  ; mutable text : string
  }

type related_location = private
  { mutable _presence : Pbrt.Bitfield.t (** presence for 1 fields *)
  ; mutable message : string
  ; mutable location : location option
  }

type diagnostic = private
  { mutable _presence : Pbrt.Bitfield.t (** presence for 3 fields *)
  ; mutable message : string
  ; mutable location : location option
  ; mutable severity : severity
  ; mutable source : source option
  ; mutable code : code option
  ; mutable suggestions : suggestion list
  ; mutable original_output : string
  ; mutable related_locations : related_location list
  }

type diagnostic_result = private
  { mutable _presence : Pbrt.Bitfield.t (** presence for 1 fields *)
  ; mutable diagnostics : diagnostic list
  ; mutable source : source option
  ; mutable severity : severity
  }

(** {2 Basic values} *)

(** [default_position ()] is a new empty value for type [position] *)
val default_position : unit -> position

(** [default_range ()] is a new empty value for type [range] *)
val default_range : unit -> range

(** [default_location ()] is a new empty value for type [location] *)
val default_location : unit -> location

(** [default_severity ()] is a new empty value for type [severity] *)
val default_severity : unit -> severity

(** [default_source ()] is a new empty value for type [source] *)
val default_source : unit -> source

(** [default_code ()] is a new empty value for type [code] *)
val default_code : unit -> code

(** [default_suggestion ()] is a new empty value for type [suggestion] *)
val default_suggestion : unit -> suggestion

(** [default_related_location ()] is a new empty value for type [related_location] *)
val default_related_location : unit -> related_location

(** [default_diagnostic ()] is a new empty value for type [diagnostic] *)
val default_diagnostic : unit -> diagnostic

(** [default_diagnostic_result ()] is a new empty value for type [diagnostic_result] *)
val default_diagnostic_result : unit -> diagnostic_result

(** {2 Make functions} *)

(** [make_position … ()] is a builder for type [position] *)
val make_position : ?line:int32 -> ?column:int32 -> unit -> position

val copy_position : position -> position

(** presence of field "line" in [position] *)
val position_has_line : position -> bool

(** set field line in position *)
val position_set_line : position -> int32 -> unit

(** presence of field "column" in [position] *)
val position_has_column : position -> bool

(** set field column in position *)
val position_set_column : position -> int32 -> unit

(** [make_range … ()] is a builder for type [range] *)
val make_range : ?start:position -> ?end_:position -> unit -> range

val copy_range : range -> range

(** set field start in range *)
val range_set_start : range -> position -> unit

(** set field end_ in range *)
val range_set_end_ : range -> position -> unit

(** [make_location … ()] is a builder for type [location] *)
val make_location : ?path:string -> ?range:range -> unit -> location

val copy_location : location -> location

(** presence of field "path" in [location] *)
val location_has_path : location -> bool

(** set field path in location *)
val location_set_path : location -> string -> unit

(** set field range in location *)
val location_set_range : location -> range -> unit

(** [make_source … ()] is a builder for type [source] *)
val make_source : ?name:string -> ?url:string -> unit -> source

val copy_source : source -> source

(** presence of field "name" in [source] *)
val source_has_name : source -> bool

(** set field name in source *)
val source_set_name : source -> string -> unit

(** presence of field "url" in [source] *)
val source_has_url : source -> bool

(** set field url in source *)
val source_set_url : source -> string -> unit

(** [make_code … ()] is a builder for type [code] *)
val make_code : ?value:string -> ?url:string -> unit -> code

val copy_code : code -> code

(** presence of field "value" in [code] *)
val code_has_value : code -> bool

(** set field value in code *)
val code_set_value : code -> string -> unit

(** presence of field "url" in [code] *)
val code_has_url : code -> bool

(** set field url in code *)
val code_set_url : code -> string -> unit

(** [make_suggestion … ()] is a builder for type [suggestion] *)
val make_suggestion : ?range:range -> ?text:string -> unit -> suggestion

val copy_suggestion : suggestion -> suggestion

(** set field range in suggestion *)
val suggestion_set_range : suggestion -> range -> unit

(** presence of field "text" in [suggestion] *)
val suggestion_has_text : suggestion -> bool

(** set field text in suggestion *)
val suggestion_set_text : suggestion -> string -> unit

(** [make_related_location … ()] is a builder for type [related_location] *)
val make_related_location
  :  ?message:string
  -> ?location:location
  -> unit
  -> related_location

val copy_related_location : related_location -> related_location

(** presence of field "message" in [related_location] *)
val related_location_has_message : related_location -> bool

(** set field message in related_location *)
val related_location_set_message : related_location -> string -> unit

(** set field location in related_location *)
val related_location_set_location : related_location -> location -> unit

(** [make_diagnostic … ()] is a builder for type [diagnostic] *)
val make_diagnostic
  :  ?message:string
  -> ?location:location
  -> ?severity:severity
  -> ?source:source
  -> ?code:code
  -> ?suggestions:suggestion list
  -> ?original_output:string
  -> ?related_locations:related_location list
  -> unit
  -> diagnostic

val copy_diagnostic : diagnostic -> diagnostic

(** presence of field "message" in [diagnostic] *)
val diagnostic_has_message : diagnostic -> bool

(** set field message in diagnostic *)
val diagnostic_set_message : diagnostic -> string -> unit

(** set field location in diagnostic *)
val diagnostic_set_location : diagnostic -> location -> unit

(** presence of field "severity" in [diagnostic] *)
val diagnostic_has_severity : diagnostic -> bool

(** set field severity in diagnostic *)
val diagnostic_set_severity : diagnostic -> severity -> unit

(** set field source in diagnostic *)
val diagnostic_set_source : diagnostic -> source -> unit

(** set field code in diagnostic *)
val diagnostic_set_code : diagnostic -> code -> unit

(** set field suggestions in diagnostic *)
val diagnostic_set_suggestions : diagnostic -> suggestion list -> unit

(** presence of field "original_output" in [diagnostic] *)
val diagnostic_has_original_output : diagnostic -> bool

(** set field original_output in diagnostic *)
val diagnostic_set_original_output : diagnostic -> string -> unit

(** set field related_locations in diagnostic *)
val diagnostic_set_related_locations : diagnostic -> related_location list -> unit

(** [make_diagnostic_result … ()] is a builder for type [diagnostic_result] *)
val make_diagnostic_result
  :  ?diagnostics:diagnostic list
  -> ?source:source
  -> ?severity:severity
  -> unit
  -> diagnostic_result

val copy_diagnostic_result : diagnostic_result -> diagnostic_result

(** set field diagnostics in diagnostic_result *)
val diagnostic_result_set_diagnostics : diagnostic_result -> diagnostic list -> unit

(** set field source in diagnostic_result *)
val diagnostic_result_set_source : diagnostic_result -> source -> unit

(** presence of field "severity" in [diagnostic_result] *)
val diagnostic_result_has_severity : diagnostic_result -> bool

(** set field severity in diagnostic_result *)
val diagnostic_result_set_severity : diagnostic_result -> severity -> unit

(** {2 Protobuf YoJson Encoding} *)

(** [encode_json_position v encoder] encodes [v] to to json *)
val encode_json_position : position -> Yojson.Basic.t

(** [encode_json_range v encoder] encodes [v] to to json *)
val encode_json_range : range -> Yojson.Basic.t

(** [encode_json_location v encoder] encodes [v] to to json *)
val encode_json_location : location -> Yojson.Basic.t

(** [encode_json_severity v encoder] encodes [v] to to json *)
val encode_json_severity : severity -> Yojson.Basic.t

(** [encode_json_source v encoder] encodes [v] to to json *)
val encode_json_source : source -> Yojson.Basic.t

(** [encode_json_code v encoder] encodes [v] to to json *)
val encode_json_code : code -> Yojson.Basic.t

(** [encode_json_suggestion v encoder] encodes [v] to to json *)
val encode_json_suggestion : suggestion -> Yojson.Basic.t

(** [encode_json_related_location v encoder] encodes [v] to to json *)
val encode_json_related_location : related_location -> Yojson.Basic.t

(** [encode_json_diagnostic v encoder] encodes [v] to to json *)
val encode_json_diagnostic : diagnostic -> Yojson.Basic.t

(** [encode_json_diagnostic_result v encoder] encodes [v] to to json *)
val encode_json_diagnostic_result : diagnostic_result -> Yojson.Basic.t

(** {2 JSON Decoding} *)

(** [decode_json_position decoder] decodes a [position] value from [decoder] *)
val decode_json_position : Yojson.Basic.t -> position

(** [decode_json_range decoder] decodes a [range] value from [decoder] *)
val decode_json_range : Yojson.Basic.t -> range

(** [decode_json_location decoder] decodes a [location] value from [decoder] *)
val decode_json_location : Yojson.Basic.t -> location

(** [decode_json_severity decoder] decodes a [severity] value from [decoder] *)
val decode_json_severity : Yojson.Basic.t -> severity

(** [decode_json_source decoder] decodes a [source] value from [decoder] *)
val decode_json_source : Yojson.Basic.t -> source

(** [decode_json_code decoder] decodes a [code] value from [decoder] *)
val decode_json_code : Yojson.Basic.t -> code

(** [decode_json_suggestion decoder] decodes a [suggestion] value from [decoder] *)
val decode_json_suggestion : Yojson.Basic.t -> suggestion

(** [decode_json_related_location decoder] decodes a [related_location] value from [decoder]
*)
val decode_json_related_location : Yojson.Basic.t -> related_location

(** [decode_json_diagnostic decoder] decodes a [diagnostic] value from [decoder] *)
val decode_json_diagnostic : Yojson.Basic.t -> diagnostic

(** [decode_json_diagnostic_result decoder] decodes a [diagnostic_result] value from [decoder]
*)
val decode_json_diagnostic_result : Yojson.Basic.t -> diagnostic_result
