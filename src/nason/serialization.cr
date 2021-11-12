module NASON
  annotation Field
  end

  # The `NASON::Serializable` module automatically generates methods for NASON serialization when included.
  #
  # ### Example
  #
  # ```
  # require "nason"
  #
  # class Location
  #   include NASON::Serializable
  #
  #   @[NASON::Field(key: "lat")]
  #   property latitude : Float64
  #
  #   @[NASON::Field(key: "lng")]
  #   property longitude : Float64
  # end
  #
  # class House
  #   include NASON::Serializable
  #   property address : String
  #   property location : Location?
  # end
  #
  # house = House.from_json(%({"address": "Crystal Road 1234", "location": {"lat": 12.3, "lng": 34.5}}))
  # house.address  # => "Crystal Road 1234"
  # house.location # => #<Location:0x10cd93d80 @latitude=12.3, @longitude=34.5>
  # house.to_json  # => %({"address":"Crystal Road 1234","location":{"lat":12.3,"lng":34.5}})
  #
  # houses = Array(House).from_json(%([{"address": "Crystal Road 1234", "location": {"lat": 12.3, "lng": 34.5}}]))
  # houses.size    # => 1
  # houses.to_json # => %([{"address":"Crystal Road 1234","location":{"lat":12.3,"lng":34.5}}])
  # ```
  #
  # ### Usage
  #
  # Including `NASON::Serializable` will create `#to_json` and `self.from_json` methods on the current class,
  # and a constructor which takes a `NASON::PullParser`. By default, these methods serialize into a json
  # object containing the value of every instance variable, the keys being the instance variable name.
  # Most primitives and collections supported as instance variable values (string, integer, array, hash, etc.),
  # along with objects which define to_json and a constructor taking a `NASON::PullParser`.
  # Union types are also supported, including unions with nil. If multiple types in a union parse correctly,
  # it is undefined which one will be chosen.
  #
  # To change how individual instance variables are parsed and serialized, the annotation `NASON::Field`
  # can be placed on the instance variable. Annotating property, getter and setter macros is also allowed.
  # You need add type `Null` to the field if the field is allowed to have null value.
  # To set null value to the field, just assign constant `NULL` to it.
  # ```
  # require "nason"
  #
  # class A
  #   include NASON::Serializable
  #
  #   @[NASON::Field(key: "my_key")]
  #   property a : Int32? | Null
  # end
  #
  # obj = A.from_json(%({"my_key":null})) # => A(@a=null)
  # obj.a                                 # => null
  # obj.a == NULL                         # => true
  # obj.to_json                           # => "{\"my_key\":null}"
  # ```
  #
  # `NASON::Field` properties:
  # * **ignore**: if `true` skip this field in serialization and deserialization (by default false)
  # * **ignore_serialize**: if `true` skip this field in serialization (by default false)
  # * **ignore_deserialize**: if `true` skip this field in deserialization (by default false)
  # * **key**: the value of the key in the json object (by default the name of the instance variable)
  # * **root**: assume the value is inside a NASON object with a given key (see `Object.from_json(string_or_io, root)`)
  # * **converter**: specify an alternate type for parsing and generation. The converter must define `from_json(NASON::PullParser)` and `to_json(value, NASON::Builder)`. Examples of converters are a `Time::Format` instance and `Time::EpochConverter` for `Time`.
  # * **presence**: if `true`, a `@{{key}}_present` instance variable will be generated when the key was present (even if it has a `null` value), `false` by default
  #
  # Deserialization also respects default values of variables:
  # ```
  # require "nason"
  #
  # struct A
  #   include NASON::Serializable
  #   @a : Int32
  #   @b : Float64 = 1.0
  # end
  #
  # A.from_json(%<{"a":1}>) # => A(@a=1, @b=1.0)
  # ```
  #
  # ### Extensions: `NASON::Serializable::Strict` and `NASON::Serializable::Unmapped`.
  #
  # If the `NASON::Serializable::Strict` module is included, unknown properties in the NASON
  # document will raise a parse exception. By default the unknown properties
  # are silently ignored.
  # If the `NASON::Serializable::Unmapped` module is included, unknown properties in the NASON
  # document will be stored in a `Hash(String, NASON::Any)`. On serialization, any keys inside json_unmapped
  # will be serialized and appended to the current json object.
  # ```
  # require "nason"
  #
  # struct A
  #   include NASON::Serializable
  #   include NASON::Serializable::Unmapped
  #   @a : Int32
  # end
  #
  # a = A.from_json(%({"a":1,"b":2})) # => A(@json_unmapped={"b" => 2_i64}, @a=1)
  # a.to_json                         # => {"a":1,"b":2}
  # ```
  #
  # ### Discriminator field
  #
  # A very common NASON serialization strategy for handling different objects
  # under a same hierarchy is to use a discriminator field. For example in
  # [GeoNASON](https://tools.ietf.org/html/rfc7946) each object has a "type"
  # field, and the rest of the fields, and their meaning, depend on its value.
  #
  # You can use `NASON::Serializable.use_json_discriminator` for this use case.
  module Serializable
    annotation Options
    end

    macro included
      # Define a `new` directly in the included type,
      # so it overloads well with other possible initializes

      def self.new(pull : ::NASON::PullParser)
        new_from_json_pull_parser(pull)
      end

      private def self.new_from_json_pull_parser(pull : ::NASON::PullParser)
        instance = allocate
        instance.initialize(__pull_for_json_serializable: pull)
        GC.add_finalizer(instance) if instance.responds_to?(:finalize)
        instance
      end

      # When the type is inherited, carry over the `new`
      # so it can compete with other possible initializes

      macro inherited
        def self.new(pull : ::NASON::PullParser)
          new_from_json_pull_parser(pull)
        end
      end
    end

    def initialize(*, __pull_for_json_serializable pull : ::NASON::PullParser)
      {% begin %}
        {% properties = {} of Nil => Nil %}
        {% for ivar in @type.instance_vars %}
          {% ann = ivar.annotation(::NASON::Field) %}
          {% unless ann && (ann[:ignore] || ann[:ignore_deserialize]) %}
            {%
              properties[ivar.id] = {
                type:        ivar.type,
                key:         ((ann && ann[:key]) || ivar).id.stringify,
                has_default: ivar.has_default_value?,
                default:     ivar.default_value,
                nilable:     ivar.type.nilable?,
                nullable:    ivar.type.union? && ivar.type.union_types.any? { |t| t.stringify == "Null" },
                root:        ann && ann[:root],
                converter:   ann && ann[:converter],
                presence:    ann && ann[:presence],
              }
            %}
          {% end %}
        {% end %}

        {% for name, value in properties %}
          %var{name} = nil
          %found{name} = false
        {% end %}

        %location = pull.location
        begin
          pull.read_begin_object
        rescue exc : ::NASON::ParseException
          raise ::NASON::SerializableError.new(exc.message, self.class.to_s, nil, *%location, exc)
        end
        until pull.kind.end_object?
          %key_location = pull.location
          key = pull.read_object_key
          case key
          {% for name, value in properties %}
            when {{value[:key]}}
              %found{name} = true
              begin
                {% if !value[:nullable] %}
                pull.raise "Expecting none null value but got null for {{name}}" if pull.kind.null?
                {% end %}

                %var{name} =
                  {% if value[:nullable] %} pull.read_null_or { {% end %}

                  {% if value[:root] %}
                    pull.on_key!({{value[:root]}}) do
                  {% end %}

                  {% if value[:converter] %}
                    {{value[:converter]}}.from_json(pull)
                  {% else %}
                    ::Union({{value[:type]}}).new(pull)
                  {% end %}

                  {% if value[:root] %}
                    end
                  {% end %}

                {% if value[:nullable] %} } {% end %}
              rescue exc : ::NASON::ParseException
                raise ::NASON::SerializableError.new(exc.message, self.class.to_s, {{value[:key]}}, *%key_location, exc)
              end
          {% end %}
          else
            on_unknown_json_attribute(pull, key, %key_location)
          end
        end
        pull.read_next

        {% for name, value in properties %}
          {% unless value[:nilable] || value[:has_default] %}
            if %var{name}.nil? && !%found{name} && !::Union({{value[:type]}}).nilable?
              raise ::NASON::SerializableError.new("Missing JSON attribute: {{value[:key].id}}", self.class.to_s, nil, *%location, nil)
            end
          {% end %}

          {% if value[:nilable] %}
            {% if value[:has_default] != nil %}
              @{{name}} = %found{name} ? %var{name} : {{value[:default]}}
            {% else %}
              @{{name}} = %var{name}
            {% end %}
          {% elsif value[:has_default] %}
            if %found{name} && !%var{name}.nil?
              @{{name}} = %var{name}
            end
          {% else %}
            @{{name}} = (%var{name}).as({{value[:type]}})
          {% end %}

          {% if value[:presence] %}
            @{{name}}_present = %found{name}
          {% end %}
        {% end %}
      {% end %}
      after_initialize
    end

    protected def after_initialize
    end

    protected def on_unknown_json_attribute(pull, key, key_location)
      pull.skip
    end

    protected def on_to_json(json : ::NASON::Builder)
    end

    def to_json(json : ::NASON::Builder)
      {% begin %}
        {% properties = {} of Nil => Nil %}
        {% for ivar in @type.instance_vars %}
          {% ann = ivar.annotation(::NASON::Field) %}
          {% unless ann && (ann[:ignore] || ann[:ignore_serialize]) %}
            {%
              properties[ivar.id] = {
                type:      ivar.type,
                key:       ((ann && ann[:key]) || ivar).id.stringify,
                root:      ann && ann[:root],
                converter: ann && ann[:converter],
              }
            %}
          {% end %}
        {% end %}

        json.object do
          {% for name, value in properties %}
            _{{name}} = @{{name}}
              unless _{{name}}.nil?
                json.field({{value[:key]}}) do
                  {% if value[:root] %}

                    json.object do
                      json.field({{value[:root]}}) do
                  {% end %}

                  {% if value[:converter] %}
                    if _{{name}}
                      {{ value[:converter] }}.to_json(_{{name}}, json)
                    else
                      nil.to_json(json)
                    end
                  {% else %}
                    _{{name}}.to_json(json)
                  {% end %}

                  {% if value[:root] %}
                      end
                    end
                  {% end %}
                end
              end
          {% end %}
          on_to_json(json)
        end
      {% end %}
    end

    module Strict
      protected def on_unknown_json_attribute(pull, key, key_location)
        raise ::NASON::SerializableError.new("Unknown NASON attribute: #{key}", self.class.to_s, nil, *key_location, nil)
      end
    end

    module Unmapped
      @[NASON::Field(ignore: true)]
      property json_unmapped = Hash(String, NASON::Any).new

      protected def on_unknown_json_attribute(pull, key, key_location)
        json_unmapped[key] = begin
          NASON::Any.new(pull)
        rescue exc : ::NASON::ParseException
          raise ::NASON::SerializableError.new(exc.message, self.class.to_s, key, *key_location, exc)
        end
      end

      protected def on_to_json(json)
        json_unmapped.each do |key, value|
          json.field(key) { value.to_json(json) }
        end
      end
    end

    # Tells this class to decode NASON by using a field as a discriminator.
    #
    # - *field* must be the field name to use as a discriminator
    # - *mapping* must be a hash or named tuple where each key-value pair
    #   maps a discriminator value to a class to deserialize
    #
    # For example:
    #
    # ```
    # require "nason"
    #
    # abstract class Shape
    #   include NASON::Serializable
    #
    #   use_json_discriminator "type", {point: Point, circle: Circle}
    #
    #   property type : String
    # end
    #
    # class Point < Shape
    #   property x : Int32
    #   property y : Int32
    # end
    #
    # class Circle < Shape
    #   property x : Int32
    #   property y : Int32
    #   property radius : Int32
    # end
    #
    # Shape.from_json(%({"type": "point", "x": 1, "y": 2}))               # => #<Point:0x10373ae20 @type="point", @x=1, @y=2>
    # Shape.from_json(%({"type": "circle", "x": 1, "y": 2, "radius": 3})) # => #<Circle:0x106a4cea0 @type="circle", @x=1, @y=2, @radius=3>
    # ```
    macro use_json_discriminator(field, mapping)
      {% unless mapping.is_a?(HashLiteral) || mapping.is_a?(NamedTupleLiteral) %}
        {% mapping.raise "mapping argument must be a HashLiteral or a NamedTupleLiteral, not #{mapping.class_name.id}" %}
      {% end %}

      def self.new(pull : ::NASON::PullParser)
        location = pull.location

        discriminator_value = nil

        # Try to find the discriminator while also getting the raw
        # string value of the parsed NASON, so then we can pass it
        # to the final type.
        json = String.build do |io|
          NASON.build(io) do |builder|
            builder.start_object
            pull.read_object do |key|
              if key == {{field.id.stringify}}
                value_kind = pull.kind
                case value_kind
                when .string?
                  discriminator_value = pull.string_value
                when .int?
                  discriminator_value = pull.int_value
                when .bool?
                  discriminator_value = pull.bool_value
                else
                  raise ::NASON::SerializableError.new("NASON discriminator field '{{field.id}}' has an invalid value type of #{value_kind.to_s}", to_s, nil, *location, nil)
                end
                builder.field(key, discriminator_value)
                pull.read_next
              else
                builder.field(key) { pull.read_raw(builder) }
              end
            end
            builder.end_object
          end
        end

        unless discriminator_value
          raise ::NASON::SerializableError.new("Missing JSON discriminator field '{{field.id}}'", to_s, nil, *location, nil)
        end

        case discriminator_value
        {% for key, value in mapping %}
          {% if mapping.is_a?(NamedTupleLiteral) %}
            when {{key.id.stringify}}
          {% else %}
            {% if key.is_a?(StringLiteral) %}
              when {{key}}
            {% elsif key.is_a?(NumberLiteral) || key.is_a?(BoolLiteral) %}
              when {{key.id}}
            {% elsif key.is_a?(Path) %}
              when {{key.resolve}}
            {% else %}
              {% key.raise "mapping keys must be one of StringLiteral, NumberLiteral, BoolLiteral, or Path, not #{key.class_name.id}" %}
            {% end %}
          {% end %}
          {{value.id}}.from_json(json)
        {% end %}
        else
          raise ::NASON::SerializableError.new("Unknown '{{field.id}}' discriminator value: #{discriminator_value.inspect}", to_s, nil, *location, nil)
        end
      end
    end
  end

  class SerializableError < ParseException
    getter klass : String
    getter attribute : String?

    def initialize(message : String?, @klass : String, @attribute : String?, line_number : Int32, column_number : Int32, cause)
      message = String.build do |io|
        io << message
        io << "\n  parsing "
        io << klass
        if attribute = @attribute
          io << '#' << attribute
        end
      end
      super(message, line_number, column_number, cause)
      if cause
        @line_number, @column_number = cause.location
      end
    end
  end
end
