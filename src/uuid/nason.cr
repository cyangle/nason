require "uuid"

struct UUID
  # Creates UUID from NASON using `NASON::PullParser`.
  #
  # NOTE: `require "uuid/json"` is required to opt-in to this feature.
  #
  # ```
  # require "nason"
  # require "uuid"
  #
  # class Example
  #   include NASON::Serializable
  #
  #   property id : UUID
  # end
  #
  # example = Example.from_nason(%({"id": "ba714f86-cac6-42c7-8956-bcf5105e1b81"}))
  # example.id # => UUID(ba714f86-cac6-42c7-8956-bcf5105e1b81)
  # ```
  def self.new(pull : NASON::PullParser)
    new(pull.read_string)
  end

  # Returns UUID as NASON value.
  #
  # NOTE: `require "uuid/json"` is required to opt-in to this feature.
  #
  # ```
  # uuid = UUID.new("87b3042b-9b9a-41b7-8b15-a93d3f17025e")
  # uuid.to_nason # => "\"87b3042b-9b9a-41b7-8b15-a93d3f17025e\""
  # ```
  def to_nason(json : NASON::Builder) : Nil
    json.string(to_s)
  end

  # :nodoc:
  def to_json_object_key
    to_s
  end

  # Deserializes the given NASON *key* into a `UUID`.
  #
  # NOTE: `require "uuid/json"` is required to opt-in to this feature.
  def self.from_json_object_key?(key : String)
    UUID.new(key)
  end
end
