class NullAssertionError < Exception
  def initialize(message = "Null assertion failed")
    super(message)
  end
end

struct Null
  # Returns `0_u64`. Even though `Null` is not a `Reference` type, it is usually
  # mixed with them to form nilable types so it's useful to have an
  # object id for `nil`.
  # Returns `true`: `Null` has only one singleton value: `nil`.
  def ==(other : Null)
    true
  end

  # Returns `true`: `Null` has only one singleton value: `nil`.
  def same?(other : Null)
    true
  end

  # Returns `false`.
  def same?(other : Reference) : Bool
    false
  end

  # Returns `"null"`
  def to_s : String
    "null"
  end

  def to_yaml(yaml : YAML::Nodes::Builder) : Nil
    yaml.scalar "null"
  end

  # Appends `"null"` to the given IO.
  def to_s(io : IO) : Nil
    io << to_s
  end

  # Returns `"nil"`.
  def inspect : String
    "null"
  end

  # Writes `"null"` to the given `IO`.
  def inspect(io : IO) : Nil
    io << "null"
  end

  # Doesn't yield to the block.
  #
  # See also: `Object#try`.
  def try(&block)
    yield self
  end

  # Raises `NullAssertionError`.
  #
  # See also: `Object#not_nil!`.
  def not_nil! : Null
    self
  end

  def not_null! : NoReturn
    raise NullAssertionError.new
  end

  # Returns `self`.
  # This method enables to call the `presence` method (see `String#presence`) on a union with `Null`.
  # The idea is to return `nil` when the value is `nil` or empty.
  #
  # ```
  # config = {"empty" => ""}
  # config["empty"]?.presence   # => nil
  # config["missing"]?.presence # => nil
  # ```
  def presence : Nil
    nil
  end

  def clone
    self
  end

  def initialize
  end

  @@null = Null.new

  def self.null : Null
    @@null
  end

  def self.new(pull : NASON::PullParser)
    pull.read_null
  end

  def to_nason(nson : NASON::Builder) : Nil
    nson.null
  end

  def to_json_object_key : String
    ""
  end
end

NULL = Null.null

class Object
  def null?
    self == NULL
  end

  def nil_or_null?
    nil? || null?
  end

  def not_null!
    self
  end

  def present?
    !nil? && !null?
  end

  def present!
    not_nil!.not_null!
  end
end
