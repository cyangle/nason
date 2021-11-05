# The NASON module allows parsing and generating [NASON](http://json.org/) documents.
#
# ### General type-safe interface
#
# The general type-safe interface for parsing NASON is to invoke `T.from_json` on a
# target type `T` and pass either a `String` or `IO` as an argument.
#
# ```
# require "nason"
#
# json_text = %([1, 2, 3])
# Array(Int32).from_json(json_text) # => [1, 2, 3]
#
# json_text = %({"x": 1, "y": 2})
# Hash(String, Int32).from_json(json_text) # => {"x" => 1, "y" => 2}
# ```
#
# Serializing is achieved by invoking `to_json`, which returns a `String`, or
# `to_json(io : IO)`, which will stream the NASON to an `IO`.
#
# ```
# require "nason"
#
# [1, 2, 3].to_json            # => "[1,2,3]"
# {"x" => 1, "y" => 2}.to_json # => "{\"x\":1,\"y\":2}"
# ```
#
# Most types in the standard library implement these methods. For user-defined types
# you can define a `self.new(pull : NASON::PullParser)` for parsing and
# `to_json(builder : NASON::Builder)` for serializing. The following sections
# show convenient ways to do this using `NASON::Serializable`.
#
# NOTE: NASON object keys are always strings but they can still be parsed
# and deserialized to other types. To deserialize, define a
# `T.from_json_object_key?(key : String) : T?` method, which can return `nil`
# if the string can't be parsed into that type. To serialize, define a
# `to_json_object_key : String` method can be serialized that way.
# All integer and float types in the standard library can be deserialized that way.
#
# ```
# require "nason"
#
# json_text = %({"1": 2, "3": 4})
# Hash(Int32, Int32).from_json(json_text) # => {1 => 2, 3 => 4}
#
# {1.5 => 2}.to_json # => "{\"1.5\":2}"
# ```
#
# ### Parsing with `NASON.parse`
#
# `NASON.parse` will return an `Any`, which is a convenient wrapper around all possible NASON types,
# making it easy to traverse a complex NASON structure but requires some casts from time to time,
# mostly via some method invocations.
#
# ```
# require "nason"
#
# value = NASON.parse("[1, 2, 3]") # : NASON::Any
#
# value[0]               # => 1
# typeof(value[0])       # => NASON::Any
# value[0].as_i          # => 1
# typeof(value[0].as_i)  # => Int32
# value[0].as_i?         # => 1
# typeof(value[0].as_i?) # => Int32 | Nil
# value[0].as_s?         # => nil
# typeof(value[0].as_s?) # => String | Nil
#
# value[0] + 1       # Error, because value[0] is NASON::Any
# value[0].as_i + 10 # => 11
# ```
#
# `NASON.parse` can read from an `IO` directly (such as a file) which saves
# allocating a string:
#
# ```
# require "nason"
#
# json = File.open("path/to/file.json") do |file|
#   NASON.parse(file)
# end
# ```
#
# Parsing with `NASON.parse` is useful for dealing with a dynamic NASON structure.
#
# ### Generating with `NASON.build`
#
# Use `NASON.build`, which uses `NASON::Builder`, to generate NASON
# by emitting scalars, arrays and objects:
#
# ```
# require "nason"
#
# string = NASON.build do |json|
#   json.object do
#     json.field "name", "foo"
#     json.field "values" do
#       json.array do
#         json.number 1
#         json.number 2
#         json.number 3
#       end
#     end
#   end
# end
# string # => %<{"name":"foo","values":[1,2,3]}>
# ```
#
# ### Generating with `to_json`
#
# `to_json`, `to_json(IO)` and `to_json(NASON::Builder)` methods are provided
# for primitive types, but you need to define `to_json(NASON::Builder)`
# for custom objects, either manually or using `NASON::Serializable`.
module NASON
  VERSION = "0.1.0"
  # Generic NASON error.
  class Error < Exception
  end

  # Exception thrown on a NASON parse error.
  class ParseException < Error
    getter line_number : Int32
    getter column_number : Int32

    def initialize(message, @line_number, @column_number, cause = nil)
      super "#{message} at line #{@line_number}, column #{@column_number}", cause
    end

    def location : {Int32, Int32}
      {line_number, column_number}
    end
  end

  # Parses a NASON document as a `NASON::Any`.
  def self.parse(input : String | IO) : Any
    Parser.new(input).parse
  end
end

require "./nason/*"
require "./big/*"
require "./uuid/*"
