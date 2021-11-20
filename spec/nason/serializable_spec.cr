require "../spec_helper"
require "yaml"
# {% unless flag?(:win32) %}
# require "big"
# require "big/json"
# {% end %}
# require "uuid"
# require "uuid/json"

record JSONAttrPoint, x : Int32, y : Int32 do
  include NASON::Serializable
end

class JSONAttrEmptyClass
  include NASON::Serializable

  def initialize; end
end

class JSONAttrEmptyClassWithUnmapped
  include NASON::Serializable
  include NASON::Serializable::Unmapped

  def initialize; end
end

class JSONAttrPerson
  include NASON::Serializable

  property name : String
  property age : Int32?

  def_equals name, age

  def initialize(@name : String)
  end
end

struct JSONAttrPersonWithTwoFieldInInitialize
  include NASON::Serializable

  property name : String
  property age : Int32

  def initialize(@name, @age)
  end
end

class StrictJSONAttrPerson
  include NASON::Serializable
  include NASON::Serializable::Strict

  property name : String
  property age : Int32?
end

class JSONAttrPersonExtraFields
  include NASON::Serializable
  include NASON::Serializable::Unmapped

  property name : String
  property age : Int32?
end

class JSONAttrWithBool
  include NASON::Serializable

  property value : Bool
end

class JSONAttrWithUUID
  include NASON::Serializable

  property value : UUID
end

{% unless flag?(:win32) %}
  class JSONAttrWithBigDecimal
    include NASON::Serializable

    property value : BigDecimal
  end
{% end %}

class JSONAttrWithTime
  include NASON::Serializable

  @[NASON::Field(converter: Time::Format.new("%F %T"))]
  property value : Time
end

class JSONAttrWithNilableTime
  include NASON::Serializable

  @[NASON::Field(converter: Time::Format.new("%F"))]
  property value : Time?

  def initialize
  end
end

class JSONAttrWithPropertiesKey
  include NASON::Serializable

  property properties : Hash(String, String)
end

class JSONAttrWithSimpleMapping
  include NASON::Serializable

  property name : String
  property age : Int32
end

class JSONAttrWithKeywordsMapping
  include NASON::Serializable

  property end : Int32
  property abstract : Int32
end

class JSONAttrWithAny
  include NASON::Serializable

  property name : String
  property any : NASON::Any
end

class JSONAttrWithProblematicKeys
  include NASON::Serializable

  property key : Int32
  property pull : Int32
end

class JSONAttrWithSet
  include NASON::Serializable

  property set : Set(String)
end

class JSONAttrWithDefaults
  include NASON::Serializable

  property a : Int32 | Null = 11
  property b : String | Null = "Haha"
  property c = true
  property d = false
  property e : Bool? = false
  property f : Int32? = 1
  property g : Int32?
  property h = [1, 2, 3]
end

class JSONAttrWithSmallIntegers
  include NASON::Serializable

  property foo : Int16
  property bar : Int8
end

class JSONAttrWithTimeEpoch
  include NASON::Serializable

  @[NASON::Field(converter: Time::EpochConverter)]
  property value : Time
end

class JSONAttrWithTimeEpochMillis
  include NASON::Serializable

  @[NASON::Field(converter: Time::EpochMillisConverter)]
  property value : Time
end

class JSONAttrWithRaw
  include NASON::Serializable

  @[NASON::Field(converter: String::RawConverter)]
  property value : String
end

class JSONAttrWithRoot
  include NASON::Serializable

  @[NASON::Field(root: "heroes")]
  property result : Array(JSONAttrPerson)
end

class JSONAttrWithNilableRoot
  include NASON::Serializable

  @[NASON::Field(root: "heroes")]
  property result : Array(JSONAttrPerson)? | Null

  def initialize(@result)
  end
end

class JSONAttrWithNilableRootEmitNull
  include NASON::Serializable

  @[NASON::Field(root: "heroes", emit_null: true)]
  property result : Array(JSONAttrPerson)? | Null
end

class JSONAttrWithNilableUnion
  include NASON::Serializable

  property value : Int32? | Null
end

class JSONAttrWithNilableUnion2
  include NASON::Serializable

  property value : Int32 | Nil | Null
end

class JSONAttrWithQueryAttributes
  include NASON::Serializable

  property? foo : Bool

  @[NASON::Field(key: "is_bar")]
  property? bar : Bool = false
end

module JSONAttrModule
  property moo : Int32 = 10
end

class JSONAttrModuleTest
  include JSONAttrModule
  include NASON::Serializable

  @[NASON::Field(key: "phoo")]
  property foo = 15

  def initialize; end

  def to_tuple
    {@moo, @foo}
  end
end

class JSONAttrModuleTest2 < JSONAttrModuleTest
  property bar : Int32

  def initialize(@bar : Int32); end

  def to_tuple
    {@moo, @foo, @bar}
  end
end

struct JSONAttrPersonWithYAML
  include NASON::Serializable
  include YAML::Serializable

  property name : String
  property age : Int32?

  def initialize(@name : String, @age : Int32? = nil)
  end
end

struct JSONAttrPersonWithYAMLInitializeHook
  include NASON::Serializable
  include YAML::Serializable

  property name : String
  property age : Int32?

  def initialize(@name : String, @age : Int32? = nil)
    after_initialize
  end

  @[NASON::Field(ignore: true)]
  @[YAML::Field(ignore: true)]
  property msg : String?

  def after_initialize
    @msg = "Hello " + name
  end
end

struct JSONAttrPersonWithSelectiveSerialization
  include NASON::Serializable

  property name : String

  @[NASON::Field(ignore_serialize: true)]
  property password : String

  @[NASON::Field(ignore_deserialize: true)]
  property generated : String = "generated-internally"

  def initialize(@name : String, @password : String)
  end
end

abstract class JSONShape
  include NASON::Serializable

  use_json_discriminator "type", {point: JSONPoint, circle: JSONCircle}

  property type : String
end

class JSONPoint < JSONShape
  property x : Int32
  property y : Int32
end

class JSONCircle < JSONShape
  property x : Int32
  property y : Int32
  property radius : Int32
end

enum JSONVariableDiscriminatorEnumFoo
  Foo = 4
end

enum JSONVariableDiscriminatorEnumFoo8 : UInt8
  Foo = 1_8
end

class JSONVariableDiscriminatorValueType
  include NASON::Serializable

  use_json_discriminator "type", {
                                         0 => JSONVariableDiscriminatorNumber,
    "1"                                    => JSONVariableDiscriminatorString,
    true                                   => JSONVariableDiscriminatorBool,
    JSONVariableDiscriminatorEnumFoo::Foo  => JSONVariableDiscriminatorEnum,
    JSONVariableDiscriminatorEnumFoo8::Foo => JSONVariableDiscriminatorEnum8,
  }
end

class JSONVariableDiscriminatorNumber < JSONVariableDiscriminatorValueType
end

class JSONVariableDiscriminatorString < JSONVariableDiscriminatorValueType
end

class JSONVariableDiscriminatorBool < JSONVariableDiscriminatorValueType
end

class JSONVariableDiscriminatorEnum < JSONVariableDiscriminatorValueType
end

class JSONVariableDiscriminatorEnum8 < JSONVariableDiscriminatorValueType
end

module JSONNamespace
  struct FooRequest
    include NASON::Serializable

    getter foo : Foo
    getter bar = Bar.new
  end

  struct Foo
    include NASON::Serializable
    getter id = "id:foo"
  end

  struct Bar
    include NASON::Serializable
    getter id = "id:bar"

    def initialize # Allow for default value above
    end
  end
end

describe "NASON mapping" do
  it "works with record" do
    JSONAttrPoint.new(1, 2).to_nason.should eq "{\"x\":1,\"y\":2}"
    JSONAttrPoint.from_nason(%({"x": 1, "y": 2})).should eq JSONAttrPoint.new(1, 2)
  end

  it "empty class" do
    e = JSONAttrEmptyClass.new
    e.to_nason.should eq "{}"
    JSONAttrEmptyClass.from_nason("{}")
  end

  it "empty class with unmapped" do
    JSONAttrEmptyClassWithUnmapped.from_nason(%({"name": "John", "age": 30})).json_unmapped.should eq({"name" => "John", "age" => 30})
  end

  it "parses person" do
    person = JSONAttrPerson.from_nason(%({"name": "John", "age": 30}))
    person.should be_a(JSONAttrPerson)
    person.name.should eq("John")
    person.age.should eq(30)
  end

  it "parses person without age" do
    person = JSONAttrPerson.from_nason(%({"name": "John"}))
    person.should be_a(JSONAttrPerson)
    person.name.should eq("John")
    person.name.size.should eq(4) # This verifies that name is not nilable
    person.age.should be_nil
  end

  it "parses array of people" do
    people = Array(JSONAttrPerson).from_nason(%([{"name": "John"}, {"name": "Doe"}]))
    people.size.should eq(2)
  end

  it "works with class with two fields" do
    person1 = JSONAttrPersonWithTwoFieldInInitialize.from_nason(%({"name": "John", "age": 30}))
    person2 = JSONAttrPersonWithTwoFieldInInitialize.new("John", 30)
    person1.should eq person2
  end

  it "does to_nason" do
    person = JSONAttrPerson.from_nason(%({"name": "John", "age": 30}))
    person2 = JSONAttrPerson.from_nason(person.to_nason)
    person2.should eq(person)
  end

  it "parses person with unknown attributes" do
    person = JSONAttrPerson.from_nason(%({"name": "John", "age": 30, "foo": "bar"}))
    person.should be_a(JSONAttrPerson)
    person.name.should eq("John")
    person.age.should eq(30)
  end

  it "parses strict person with unknown attributes" do
    error_message = <<-'MSG'
      Unknown NASON attribute: foo
        parsing StrictJSONAttrPerson
      MSG
    ex = expect_raises ::NASON::SerializableError, error_message do
      StrictJSONAttrPerson.from_nason <<-NASON
        {
          "name": "John",
          "age": 30,
          "foo": "bar"
        }
        NASON
    end
    ex.location.should eq({4, 3})
  end

  it "should parse extra fields (JSONAttrPersonExtraFields with on_unknown_json_attribute)" do
    person = JSONAttrPersonExtraFields.from_nason(%({"name": "John", "age": 30, "x": "1", "y": 2, "z": [1,2,3]}))
    person.name.should eq("John")
    person.age.should eq(30)
    person.json_unmapped.should eq({"x" => "1", "y" => 2_i64, "z" => [1, 2, 3]})
  end

  it "should to store extra fields (JSONAttrPersonExtraFields with on_to_json)" do
    person = JSONAttrPersonExtraFields.from_nason(%({"name": "John", "age": 30, "x": "1", "y": 2, "z": [1,2,3]}))
    person.name = "John1"
    person.json_unmapped.delete("y")
    person.json_unmapped["q"] = NASON::Any.new("w")
    person.to_nason.should eq "{\"name\":\"John1\",\"age\":30,\"x\":\"1\",\"z\":[1,2,3],\"q\":\"w\"}"
  end

  it "raises if non-nilable attribute is nil" do
    error_message = <<-'MSG'
      Missing JSON attribute: name
        parsing JSONAttrPerson at line 1, column 1
      MSG
    ex = expect_raises ::NASON::SerializableError, error_message do
      JSONAttrPerson.from_nason(%({"age": 30}))
    end
    ex.location.should eq({1, 1})
  end

  it "raises if not an object" do
    error_message = <<-'MSG'
      Expected BeginObject but was String at line 1, column 1
        parsing StrictJSONAttrPerson at line 0, column 0
      MSG
    ex = expect_raises ::NASON::SerializableError, error_message do
      StrictJSONAttrPerson.from_nason <<-NASON
        "foo"
        NASON
    end
    ex.location.should eq({1, 1})
  end

  it "raises if data type does not match" do
    error_message = <<-MSG
      Couldn't parse (Int32 | Nil) from "foo" at line 3, column 10
      MSG
    ex = expect_raises ::NASON::SerializableError, error_message do
      StrictJSONAttrPerson.from_nason <<-NASON
        {
          "name": "John",
          "age": "foo",
          "foo": "bar"
        }
        NASON
    end
    ex.location.should eq({3, 10})
  end

  it "doesn't emit null by default when doing to_nason" do
    person = JSONAttrPerson.from_nason(%({"name": "John"}))
    (person.to_nason =~ /age/).should be_falsey
  end

  it "doesn't raises on false value when not-nil" do
    json = JSONAttrWithBool.from_nason(%({"value": false}))
    json.value.should be_false
  end

  it "parses UUID" do
    uuid = JSONAttrWithUUID.from_nason(%({"value": "ba714f86-cac6-42c7-8956-bcf5105e1b81"}))
    uuid.should be_a(JSONAttrWithUUID)
    uuid.value.should eq(UUID.new("ba714f86-cac6-42c7-8956-bcf5105e1b81"))
  end

  it "parses json with Time::Format converter" do
    json = JSONAttrWithTime.from_nason(%({"value": "2014-10-31 23:37:16"}))
    json.value.should be_a(Time)
    json.value.to_s.should eq("2014-10-31 23:37:16 UTC")
    json.to_nason.should eq(%({"value":"2014-10-31 23:37:16"}))
  end

  it "allows setting a nilable property to nil" do
    person = JSONAttrPerson.new("John")
    person.age = 1
    person.age = nil
  end

  it "parses simple mapping" do
    person = JSONAttrWithSimpleMapping.from_nason(%({"name": "John", "age": 30}))
    person.should be_a(JSONAttrWithSimpleMapping)
    person.name.should eq("John")
    person.age.should eq(30)
  end

  it "outputs with converter when nilable" do
    json = JSONAttrWithNilableTime.new
    json.to_nason.should eq("{}")
  end

  it "outputs NASON with properties key" do
    input = {
      properties: {"foo" => "bar"},
    }.to_nason
    json = JSONAttrWithPropertiesKey.from_nason(input)
    json.to_nason.should eq(input)
  end

  it "parses json with keywords" do
    json = JSONAttrWithKeywordsMapping.from_nason(%({"end": 1, "abstract": 2}))
    json.end.should eq(1)
    json.abstract.should eq(2)
  end

  it "parses json with any" do
    json = JSONAttrWithAny.from_nason(%({"name": "Hi", "any": [{"x": 1}, 2, "hey", true, false, 1.5, null]}))
    json.name.should eq("Hi")
    json.any.raw.should eq([{"x" => 1}, 2, "hey", true, false, 1.5, NULL])
    json.to_nason.should eq(%({"name":"Hi","any":[{"x":1},2,"hey",true,false,1.5,null]}))
  end

  it "parses json with problematic keys" do
    json = JSONAttrWithProblematicKeys.from_nason(%({"key": 1, "pull": 2}))
    json.key.should eq(1)
    json.pull.should eq(2)
  end

  it "parses json array as set" do
    json = JSONAttrWithSet.from_nason(%({"set": ["a", "a", "b"]}))
    json.set.should eq(Set(String){"a", "b"})
  end

  it "allows small types of integer" do
    json = JSONAttrWithSmallIntegers.from_nason(%({"foo": 23, "bar": 7}))

    json.foo.should eq(23)
    typeof(json.foo).should eq(Int16)

    json.bar.should eq(7)
    typeof(json.bar).should eq(Int8)
  end

  describe "parses json with defaults" do
    it "mixed" do
      json = JSONAttrWithDefaults.from_nason(%({"a":1,"b":"bla"}))
      json.a.should eq 1
      json.b.should eq "bla"

      json = JSONAttrWithDefaults.from_nason(%({"a":1}))
      json.a.should eq 1
      json.b.should eq "Haha"

      json = JSONAttrWithDefaults.from_nason(%({"b":"bla"}))
      json.a.should eq 11
      json.b.should eq "bla"

      json = JSONAttrWithDefaults.from_nason(%({}))
      json.a.should eq 11
      json.b.should eq "Haha"

      # Default values should only be used when the property is nilable/missing
      json = JSONAttrWithDefaults.from_nason(%({"a":null,"b":null}))
      json.a.should eq NULL
      json.b.should eq NULL
    end

    it "bool" do
      json = JSONAttrWithDefaults.from_nason(%({}))
      json.c.should eq true
      typeof(json.c).should eq Bool
      json.d.should eq false
      typeof(json.d).should eq Bool

      json = JSONAttrWithDefaults.from_nason(%({"c":false}))
      json.c.should eq false
      json = JSONAttrWithDefaults.from_nason(%({"c":true}))
      json.c.should eq true

      json = JSONAttrWithDefaults.from_nason(%({"d":false}))
      json.d.should eq false
      json = JSONAttrWithDefaults.from_nason(%({"d":true}))
      json.d.should eq true
    end

    it "with nilable" do
      json = JSONAttrWithDefaults.from_nason(%({}))

      json.e.should eq false
      typeof(json.e).should eq(Bool | Nil)

      json.f.should eq 1
      typeof(json.f).should eq(Int32 | Nil)

      json.g.should eq nil
      typeof(json.g).should eq(Int32 | Nil)

      json = JSONAttrWithDefaults.from_nason(%({"e":false}))
      json.e.should eq false
      json = JSONAttrWithDefaults.from_nason(%({"e":true}))
      json.e.should eq true
    end

    it "create new array every time" do
      json = JSONAttrWithDefaults.from_nason(%({}))
      json.h.should eq [1, 2, 3]
      json.h << 4
      json.h.should eq [1, 2, 3, 4]

      json = JSONAttrWithDefaults.from_nason(%({}))
      json.h.should eq [1, 2, 3]
    end
  end

  it "uses Time::EpochConverter" do
    string = %({"value":1459859781})
    json = JSONAttrWithTimeEpoch.from_nason(string)
    json.value.should be_a(Time)
    json.value.should eq(Time.unix(1_459_859_781))
    json.to_nason.should eq(string)
  end

  it "uses Time::EpochMillisConverter" do
    string = %({"value":1459860483856})
    json = JSONAttrWithTimeEpochMillis.from_nason(string)
    json.value.should be_a(Time)
    json.value.should eq(Time.unix_ms(1_459_860_483_856))
    json.to_nason.should eq(string)
  end

  it "parses raw value from int" do
    string = %({"value":123456789123456789123456789123456789})
    json = JSONAttrWithRaw.from_nason(string)
    json.value.should eq("123456789123456789123456789123456789")
    json.to_nason.should eq(string)
  end

  it "parses raw value from float" do
    string = %({"value":123456789123456789.123456789123456789})
    json = JSONAttrWithRaw.from_nason(string)
    json.value.should eq("123456789123456789.123456789123456789")
    json.to_nason.should eq(string)
  end

  it "parses raw value from object" do
    string = %({"value":[null,true,false,{"x":[1,1.5]}]})
    json = JSONAttrWithRaw.from_nason(string)
    json.value.should eq(%([null,true,false,{"x":[1,1.5]}]))
    json.to_nason.should eq(string)
  end

  it "parses with root" do
    json = %({"result":{"heroes":[{"name":"Batman"}]}})
    result = JSONAttrWithRoot.from_nason(json)
    result.result.should be_a(Array(JSONAttrPerson))
    result.result.first.name.should eq "Batman"
    result.to_nason.should eq(json)
  end

  # TODO: Figure out why result is different
  it "parses with nilable root" do
    json = %({"result":null})
    result = JSONAttrWithNilableRoot.from_nason(json)
    result.result.should eq NULL
    result.to_nason.should eq %({"result":{"heroes":null}})
  end

  it "parses with nilable root" do
    result = JSONAttrWithNilableRoot.new(nil)
    result.result.should be_nil
    result.to_nason.should eq %({})
  end

  it "parses with nilable root" do
    json = %({"result":{"heroes":null}})
    result = JSONAttrWithNilableRoot.from_nason(json)
    result.result.should eq NULL
    result.to_nason.should eq %({"result":{"heroes":null}})
  end

  # TODO: Figure out why result is different
  it "parses with nilable root and emit null" do
    json = %({"result":null})
    result = JSONAttrWithNilableRootEmitNull.from_nason(json)
    result.result.should eq NULL
    result.to_nason.should eq %({"result":{"heroes":null}})
  end

  it "parses nilable union" do
    obj = JSONAttrWithNilableUnion.from_nason(%({"value": 1}))
    obj.value.should eq(1)
    obj.to_nason.should eq(%({"value":1}))

    obj = JSONAttrWithNilableUnion.from_nason(%({"value": null}))
    obj.value.should eq NULL
    obj.to_nason.should eq(%({"value":null}))

    obj = JSONAttrWithNilableUnion.from_nason(%({}))
    obj.value.should be_nil
    obj.to_nason.should eq(%({}))
  end

  it "parses nilable union2" do
    obj = JSONAttrWithNilableUnion2.from_nason(%({"value": 1}))
    obj.value.should eq(1)
    obj.to_nason.should eq(%({"value":1}))

    obj = JSONAttrWithNilableUnion2.from_nason(%({"value": null}))
    obj.value.should eq NULL
    obj.to_nason.should eq(%({"value":null}))

    obj = JSONAttrWithNilableUnion2.from_nason(%({}))
    obj.value.should be_nil
    obj.to_nason.should eq(%({}))
  end

  describe "with query attributes" do
    it "defines query getter" do
      json = JSONAttrWithQueryAttributes.from_nason(%({"foo": true}))
      json.foo?.should be_true
      json.bar?.should be_false
    end

    it "defines query getter with class restriction" do
      {% begin %}
        {% methods = JSONAttrWithQueryAttributes.methods %}
        {{ methods.find(&.name.==("foo?")).return_type }}.should eq(Bool)
        {{ methods.find(&.name.==("bar?")).return_type }}.should eq(Bool)
      {% end %}
    end

    it "defines non-query setter and presence methods" do
      json = JSONAttrWithQueryAttributes.from_nason(%({"foo": false}))
      json.bar = true
      json.bar?.should be_true
    end

    it "maps non-query attributes" do
      json = JSONAttrWithQueryAttributes.from_nason(%({"foo": false, "is_bar": false}))
      json.bar?.should be_false
      json.bar = true
      json.to_nason.should eq(%({"foo":false,"is_bar":true}))
    end

    it "raises if non-nilable attribute is nil" do
      error_message = <<-'MSG'
        Missing JSON attribute: foo
          parsing JSONAttrWithQueryAttributes at line 1, column 1
        MSG
      ex = expect_raises ::NASON::SerializableError, error_message do
        JSONAttrWithQueryAttributes.from_nason(%({"is_bar": true}))
      end
      ex.location.should eq({1, 1})
    end
  end

  describe "work with module and inheritance" do
    it { JSONAttrModuleTest.from_nason(%({"phoo": 20})).to_tuple.should eq({10, 20}) }
    it { JSONAttrModuleTest.from_nason(%({"phoo": 20})).to_tuple.should eq({10, 20}) }
    it { JSONAttrModuleTest2.from_nason(%({"phoo": 20, "bar": 30})).to_tuple.should eq({10, 20, 30}) }
    it { JSONAttrModuleTest2.from_nason(%({"bar": 30, "moo": 40})).to_tuple.should eq({40, 15, 30}) }
  end

  it "works together with yaml" do
    person = JSONAttrPersonWithYAML.new("Vasya", 30)
    person.to_nason.should eq "{\"name\":\"Vasya\",\"age\":30}"
    person.to_yaml.should eq "---\nname: Vasya\nage: 30\n"

    JSONAttrPersonWithYAML.from_nason(person.to_nason).should eq person
    JSONAttrPersonWithYAML.from_yaml(person.to_yaml).should eq person
  end

  it "yaml and json with after_initialize hook" do
    person = JSONAttrPersonWithYAMLInitializeHook.new("Vasya", 30)
    person.msg.should eq "Hello Vasya"

    person.to_nason.should eq "{\"name\":\"Vasya\",\"age\":30}"
    person.to_yaml.should eq "---\nname: Vasya\nage: 30\n"

    JSONAttrPersonWithYAMLInitializeHook.from_nason(person.to_nason).msg.should eq "Hello Vasya"
    JSONAttrPersonWithYAMLInitializeHook.from_yaml(person.to_yaml).msg.should eq "Hello Vasya"
  end

  it "json with selective serialization" do
    person = JSONAttrPersonWithSelectiveSerialization.new("Vasya", "P@ssw0rd")
    person.to_nason.should eq "{\"name\":\"Vasya\",\"generated\":\"generated-internally\"}"

    person_json = "{\"name\":\"Vasya\",\"generated\":\"should not set\",\"password\":\"update\"}"
    person = JSONAttrPersonWithSelectiveSerialization.from_nason(person_json)
    person.generated.should eq "generated-internally"
    person.password.should eq "update"
  end

  describe "use_json_discriminator" do
    it "deserializes with discriminator" do
      point = JSONShape.from_nason(%({"type": "point", "x": 1, "y": 2})).as(JSONPoint)
      point.x.should eq(1)
      point.y.should eq(2)

      circle = JSONShape.from_nason(%({"type": "circle", "x": 1, "y": 2, "radius": 3})).as(JSONCircle)
      circle.x.should eq(1)
      circle.y.should eq(2)
      circle.radius.should eq(3)
    end

    it "raises if missing discriminator" do
      expect_raises(::NASON::SerializableError, "Missing JSON discriminator field 'type'") do
        JSONShape.from_nason("{}")
      end
    end

    it "raises if unknown discriminator value" do
      expect_raises(::NASON::SerializableError, %(Unknown 'type' discriminator value: "unknown")) do
        JSONShape.from_nason(%({"type": "unknown"}))
      end
    end

    it "deserializes with variable discriminator value type" do
      object_number = JSONVariableDiscriminatorValueType.from_nason(%({"type": 0}))
      object_number.should be_a(JSONVariableDiscriminatorNumber)

      object_string = JSONVariableDiscriminatorValueType.from_nason(%({"type": "1"}))
      object_string.should be_a(JSONVariableDiscriminatorString)

      object_bool = JSONVariableDiscriminatorValueType.from_nason(%({"type": true}))
      object_bool.should be_a(JSONVariableDiscriminatorBool)

      object_enum = JSONVariableDiscriminatorValueType.from_nason(%({"type": 4}))
      object_enum.should be_a(JSONVariableDiscriminatorEnum)

      object_enum = JSONVariableDiscriminatorValueType.from_nason(%({"type": 18}))
      object_enum.should be_a(JSONVariableDiscriminatorEnum8)
    end
  end

  describe "namespaced classes" do
    it "lets default values use the object's own namespace" do
      request = JSONNamespace::FooRequest.from_nason(%({"foo":{}}))
      request.foo.id.should eq "id:foo"
      request.bar.id.should eq "id:bar"
    end
  end
end
