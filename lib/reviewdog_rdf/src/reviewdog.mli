(** Code for reviewdog.proto *)

(* generated from "reviewdog.proto", do not edit *)

(** {2 Types} *)

type position =
  { line : int32
  ; column : int32
  }

type range =
  { start : position option
  ; end_ : position option
  }

type location =
  { path : string
  ; range : range option
  }

type severity =
  | Unknown_severity
  | Error
  | Warning
  | Info

type source =
  { name : string
  ; url : string
  }

type code =
  { value : string
  ; url : string
  }

type suggestion =
  { range : range option
  ; text : string
  }

type related_location =
  { message : string
  ; location : location option
  }

type diagnostic =
  { message : string
  ; location : location option
  ; severity : severity
  ; source : source option
  ; code : code option
  ; suggestions : suggestion list
  ; original_output : string
  ; related_locations : related_location list
  }

type diagnostic_result =
  { diagnostics : diagnostic list
  ; source : source option
  ; severity : severity
  }

(** {2 Basic values} *)

(** [default_position ()] is the default value for type [position] *)
val default_position : ?line:int32 -> ?column:int32 -> unit -> position

(** [default_range ()] is the default value for type [range] *)
val default_range : ?start:position option -> ?end_:position option -> unit -> range

(** [default_location ()] is the default value for type [location] *)
val default_location : ?path:string -> ?range:range option -> unit -> location

(** [default_severity ()] is the default value for type [severity] *)
val default_severity : unit -> severity

(** [default_source ()] is the default value for type [source] *)
val default_source : ?name:string -> ?url:string -> unit -> source

(** [default_code ()] is the default value for type [code] *)
val default_code : ?value:string -> ?url:string -> unit -> code

(** [default_suggestion ()] is the default value for type [suggestion] *)
val default_suggestion : ?range:range option -> ?text:string -> unit -> suggestion

(** [default_related_location ()] is the default value for type [related_location] *)
val default_related_location
  :  ?message:string
  -> ?location:location option
  -> unit
  -> related_location

(** [default_diagnostic ()] is the default value for type [diagnostic] *)
val default_diagnostic
  :  ?message:string
  -> ?location:location option
  -> ?severity:severity
  -> ?source:source option
  -> ?code:code option
  -> ?suggestions:suggestion list
  -> ?original_output:string
  -> ?related_locations:related_location list
  -> unit
  -> diagnostic

(** [default_diagnostic_result ()] is the default value for type [diagnostic_result] *)
val default_diagnostic_result
  :  ?diagnostics:diagnostic list
  -> ?source:source option
  -> ?severity:severity
  -> unit
  -> diagnostic_result

(** {2 Protobuf Encoding} *)

(** [encode_pb_position v encoder] encodes [v] with the given [encoder] *)
val encode_pb_position : position -> Pbrt.Encoder.t -> unit

(** [encode_pb_range v encoder] encodes [v] with the given [encoder] *)
val encode_pb_range : range -> Pbrt.Encoder.t -> unit

(** [encode_pb_location v encoder] encodes [v] with the given [encoder] *)
val encode_pb_location : location -> Pbrt.Encoder.t -> unit

(** [encode_pb_severity v encoder] encodes [v] with the given [encoder] *)
val encode_pb_severity : severity -> Pbrt.Encoder.t -> unit

(** [encode_pb_source v encoder] encodes [v] with the given [encoder] *)
val encode_pb_source : source -> Pbrt.Encoder.t -> unit

(** [encode_pb_code v encoder] encodes [v] with the given [encoder] *)
val encode_pb_code : code -> Pbrt.Encoder.t -> unit

(** [encode_pb_suggestion v encoder] encodes [v] with the given [encoder] *)
val encode_pb_suggestion : suggestion -> Pbrt.Encoder.t -> unit

(** [encode_pb_related_location v encoder] encodes [v] with the given [encoder] *)
val encode_pb_related_location : related_location -> Pbrt.Encoder.t -> unit

(** [encode_pb_diagnostic v encoder] encodes [v] with the given [encoder] *)
val encode_pb_diagnostic : diagnostic -> Pbrt.Encoder.t -> unit

(** [encode_pb_diagnostic_result v encoder] encodes [v] with the given [encoder] *)
val encode_pb_diagnostic_result : diagnostic_result -> Pbrt.Encoder.t -> unit

(** {2 Protobuf Decoding} *)

(** [decode_pb_position decoder] decodes a [position] binary value from [decoder] *)
val decode_pb_position : Pbrt.Decoder.t -> position

(** [decode_pb_range decoder] decodes a [range] binary value from [decoder] *)
val decode_pb_range : Pbrt.Decoder.t -> range

(** [decode_pb_location decoder] decodes a [location] binary value from [decoder] *)
val decode_pb_location : Pbrt.Decoder.t -> location

(** [decode_pb_severity decoder] decodes a [severity] binary value from [decoder] *)
val decode_pb_severity : Pbrt.Decoder.t -> severity

(** [decode_pb_source decoder] decodes a [source] binary value from [decoder] *)
val decode_pb_source : Pbrt.Decoder.t -> source

(** [decode_pb_code decoder] decodes a [code] binary value from [decoder] *)
val decode_pb_code : Pbrt.Decoder.t -> code

(** [decode_pb_suggestion decoder] decodes a [suggestion] binary value from [decoder] *)
val decode_pb_suggestion : Pbrt.Decoder.t -> suggestion

(** [decode_pb_related_location decoder] decodes a [related_location] binary value from [decoder]
*)
val decode_pb_related_location : Pbrt.Decoder.t -> related_location

(** [decode_pb_diagnostic decoder] decodes a [diagnostic] binary value from [decoder] *)
val decode_pb_diagnostic : Pbrt.Decoder.t -> diagnostic

(** [decode_pb_diagnostic_result decoder] decodes a [diagnostic_result] binary value from [decoder]
*)
val decode_pb_diagnostic_result : Pbrt.Decoder.t -> diagnostic_result

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

(** {2 Services} *)
