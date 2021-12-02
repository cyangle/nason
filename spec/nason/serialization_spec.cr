require "../spec_helper"
# {% unless flag?(:win32) %}
# require "big"
# require "big/json"
# {% end %}
# require "uuid"
# require "uuid/json"

enum JSONSpecEnum
  Zero
  One
  Two
  OneHundred
end

@[Flags]
enum JSONSpecFlagEnum
  One
  Two
  OneHundred
end

describe "NASON serialization" do
  describe "from_nason" do
    it "does String.from_nason" do
      String.from_nason(%("foo bar")).should eq "foo bar"
    end

    it "does Path.from_nason" do
      Path.from_nason(%("foo/bar")).should eq(Path.new("foo/bar"))
    end

    it "does UInt64.from_json" do
      UInt64.from_nason(UInt64::MAX.to_s).should eq(UInt64::MAX)
    end

    it "raises ParserException for overflow UInt64.from_json" do
      expect_raises(NASON::ParseException, "Can't read UInt64 at line 0, column 0") do
        UInt64.from_nason("1#{UInt64::MAX}")
      end
    end

    it "does Array(Nil)#from_nason" do
      Array(Null).from_nason("[null, null]").should eq([NULL, NULL])
    end

    it "does Array(Bool)#from_nason" do
      Array(Bool).from_nason("[true, false]").should eq([true, false])
    end

    it "does Array(Int32)#from_nason" do
      Array(Int32).from_nason("[1, 2, 3]").should eq([1, 2, 3])
    end

    it "does Array(Int64)#from_nason" do
      Array(Int64).from_nason("[1, 2, 3]").should eq([1, 2, 3])
    end

    it "does Array(Float32)#from_nason" do
      Array(Float32).from_nason("[1.5, 2, 3.5]").should eq([1.5, 2.0, 3.5])
    end

    it "does Array(Float64)#from_nason" do
      Array(Float64).from_nason("[1.5, 2, 3.5]").should eq([1.5, 2, 3.5])
    end

    it "does Deque(String)#from_nason" do
      Deque(String).from_nason(%(["a", "b"])).should eq(Deque.new(["a", "b"]))
    end

    it "does Hash(String, String)#from_nason" do
      Hash(String, String).from_nason(%({"foo": "x", "bar": "y"})).should eq({"foo" => "x", "bar" => "y"})
    end

    it "does Hash(String, Int32)#from_nason" do
      Hash(String, Int32).from_nason(%({"foo": 1, "bar": 2})).should eq({"foo" => 1, "bar" => 2})
    end

    it "does Hash(Int32, String)#from_nason" do
      Hash(Int32, String).from_nason(%({"1": "x", "2": "y"})).should eq({1 => "x", 2 => "y"})
    end

    it "does Hash(Float32, String)#from_nason" do
      Hash(Float32, String).from_nason(%({"1.23": "x", "4.56": "y"})).should eq({1.23_f32 => "x", 4.56_f32 => "y"})
    end

    it "does Hash(Float64, String)#from_nason" do
      Hash(Float64, String).from_nason(%({"1.23": "x", "4.56": "y"})).should eq({1.23 => "x", 4.56 => "y"})
    end

    it "raises an error Hash(String, Int32)#from_nason with null value" do
      expect_raises(NASON::ParseException, "Expected Int but was Null") do
        Hash(String, Int32).from_nason(%({"foo": 1, "bar": 2, "baz": null}))
      end
    end

    it "does for Array(Int32) from IO" do
      io = IO::Memory.new "[1, 2, 3]"
      Array(Int32).from_nason(io).should eq([1, 2, 3])
    end

    it "does for Array(Int32) with block" do
      elements = [] of Int32
      ret = Array(Int32).from_nason("[1, 2, 3]") do |element|
        elements << element
      end
      ret.should be_nil
      elements.should eq([1, 2, 3])
    end

    it "does for tuple" do
      tuple = Tuple(Int32, String).from_nason(%([1, "hello"]))
      tuple.should eq({1, "hello"})
      tuple.should be_a(Tuple(Int32, String))
    end

    it "does for named tuple" do
      tuple = NamedTuple(x: Int32, y: String).from_nason(%({"y": "hello", "x": 1}))
      tuple.should eq({x: 1, y: "hello"})
      tuple.should be_a(NamedTuple(x: Int32, y: String))
    end

    it "does for named tuple with nilable fields (#8089)" do
      tuple = NamedTuple(x: Int32?, y: String).from_nason(%({"y": "hello"}))
      tuple.should eq({x: nil, y: "hello"})
      tuple.should be_a(NamedTuple(x: Int32?, y: String))
    end

    it "does for named tuple with nullable fields and null (#8089)" do
      tuple = NamedTuple(x: Int32 | Null, y: String).from_nason(%({"y": "hello", "x": null}))
      tuple.should eq({x: NULL, y: "hello"})
      tuple.should be_a(NamedTuple(x: Int32 | Null, y: String))
    end

    it "does for named tuple with spaces in key (#10918)" do
      tuple = NamedTuple(a: Int32, "xyz b-23": Int32).from_nason %{{"a": 1, "xyz b-23": 2}}
      tuple.should eq({a: 1, "xyz b-23": 2})
      tuple.should be_a NamedTuple(a: Int32, "xyz b-23": Int32)
    end

    it "does for named tuple with spaces in key and quote char (#10918)" do
      tuple = NamedTuple(a: Int32, "xyz \"foo\" b-23": Int32).from_nason %{{"a": 1, "xyz \\"foo\\" b-23": 2}}
      tuple.should eq({a: 1, "xyz \"foo\" b-23": 2})
      tuple.should be_a NamedTuple(a: Int32, "xyz \"foo\" b-23": Int32)
    end

    it "does for UUID (hyphenated)" do
      uuid = UUID.from_nason("\"ee843b26-56d8-472b-b343-0b94ed9077ff\"")
      uuid.should be_a(UUID)
      uuid.should eq(UUID.new("ee843b26-56d8-472b-b343-0b94ed9077ff"))
    end

    it "does for UUID (hex)" do
      uuid = UUID.from_nason("\"ee843b2656d8472bb3430b94ed9077ff\"")
      uuid.should be_a(UUID)
      uuid.should eq(UUID.new("ee843b26-56d8-472b-b343-0b94ed9077ff"))
    end

    it "does for UUID (urn)" do
      uuid = UUID.from_nason("\"urn:uuid:ee843b26-56d8-472b-b343-0b94ed9077ff\"")
      uuid.should be_a(UUID)
      uuid.should eq(UUID.new("ee843b26-56d8-472b-b343-0b94ed9077ff"))
    end

    describe "Enum" do
      it "normal enum" do
        JSONSpecEnum.from_nason(%("one")).should eq(JSONSpecEnum::One)
        JSONSpecEnum.from_nason(%("One")).should eq(JSONSpecEnum::One)
        JSONSpecEnum.from_nason(%("two")).should eq(JSONSpecEnum::Two)
        JSONSpecEnum.from_nason(%("ONE_HUNDRED")).should eq(JSONSpecEnum::OneHundred)
        expect_raises(NASON::ParseException, %(Unknown enum JSONSpecEnum value: "ONE-HUNDRED")) do
          JSONSpecEnum.from_nason(%("ONE-HUNDRED"))
        end
        expect_raises(NASON::ParseException, %(Unknown enum JSONSpecEnum value: " one ")) do
          JSONSpecEnum.from_nason(%(" one "))
        end

        expect_raises(NASON::ParseException, %(Unknown enum JSONSpecEnum value: "three")) do
          JSONSpecEnum.from_nason(%("three"))
        end
        expect_raises(NASON::ParseException, %(Expected String but was Int)) do
          JSONSpecEnum.from_nason(%(1))
        end
        expect_raises(NASON::ParseException, %(Unknown enum JSONSpecEnum value: "1")) do
          JSONSpecEnum.from_nason(%("1"))
        end

        expect_raises(NASON::ParseException, "Expected String but was BeginObject") do
          JSONSpecEnum.from_nason(%({}))
        end
        expect_raises(NASON::ParseException, "Expected String but was BeginArray") do
          JSONSpecEnum.from_nason(%([]))
        end
      end

      it "flag enum" do
        JSONSpecFlagEnum.from_nason(%(["one"])).should eq(JSONSpecFlagEnum::One)
        JSONSpecFlagEnum.from_nason(%(["One"])).should eq(JSONSpecFlagEnum::One)
        JSONSpecFlagEnum.from_nason(%(["one", "one"])).should eq(JSONSpecFlagEnum::One)
        JSONSpecFlagEnum.from_nason(%(["one", "two"])).should eq(JSONSpecFlagEnum::One | JSONSpecFlagEnum::Two)
        JSONSpecFlagEnum.from_nason(%(["one", "two", "one_hundred"])).should eq(JSONSpecFlagEnum::All)
        JSONSpecFlagEnum.from_nason(%([])).should eq(JSONSpecFlagEnum::None)

        expect_raises(NASON::ParseException, "Expected String but was BeginArray") do
          JSONSpecFlagEnum.from_nason(%(["one", ["two"]]))
        end

        expect_raises(NASON::ParseException, %(Unknown enum JSONSpecFlagEnum value: "three")) do
          JSONSpecFlagEnum.from_nason(%(["one", "three"]))
        end
        expect_raises(NASON::ParseException, %(Expected String but was Int)) do
          JSONSpecFlagEnum.from_nason(%([1, 2]))
        end
        expect_raises(NASON::ParseException, %(Expected String but was Int)) do
          JSONSpecFlagEnum.from_nason(%(["one", 2]))
        end
        expect_raises(NASON::ParseException, "Expected BeginArray but was BeginObject") do
          JSONSpecFlagEnum.from_nason(%({}))
        end
        expect_raises(NASON::ParseException, "Expected BeginArray but was String") do
          JSONSpecFlagEnum.from_nason(%("one"))
        end
      end
    end

    describe "Enum::ValueConverter.from_nason" do
      it "normal enum" do
        Enum::ValueConverter(JSONSpecEnum).from_nason("0").should eq(JSONSpecEnum::Zero)
        Enum::ValueConverter(JSONSpecEnum).from_nason("1").should eq(JSONSpecEnum::One)
        Enum::ValueConverter(JSONSpecEnum).from_nason("2").should eq(JSONSpecEnum::Two)
        Enum::ValueConverter(JSONSpecEnum).from_nason("3").should eq(JSONSpecEnum::OneHundred)

        expect_raises(NASON::ParseException, %(Expected Int but was String)) do
          Enum::ValueConverter(JSONSpecEnum).from_nason(%("3"))
        end
        expect_raises(NASON::ParseException, %(Unknown enum JSONSpecEnum value: 4)) do
          Enum::ValueConverter(JSONSpecEnum).from_nason("4")
        end
        expect_raises(NASON::ParseException, %(Unknown enum JSONSpecEnum value: -1)) do
          Enum::ValueConverter(JSONSpecEnum).from_nason("-1")
        end
        expect_raises(NASON::ParseException, %(Expected Int but was String)) do
          Enum::ValueConverter(JSONSpecEnum).from_nason(%(""))
        end

        expect_raises(NASON::ParseException, "Expected Int but was String") do
          Enum::ValueConverter(JSONSpecEnum).from_nason(%("one"))
        end

        expect_raises(NASON::ParseException, "Expected Int but was BeginObject") do
          Enum::ValueConverter(JSONSpecEnum).from_nason(%({}))
        end
        expect_raises(NASON::ParseException, "Expected Int but was BeginArray") do
          Enum::ValueConverter(JSONSpecEnum).from_nason(%([]))
        end
      end

      it "flag enum" do
        Enum::ValueConverter(JSONSpecFlagEnum).from_nason("0").should eq(JSONSpecFlagEnum::None)
        Enum::ValueConverter(JSONSpecFlagEnum).from_nason("1").should eq(JSONSpecFlagEnum::One)
        Enum::ValueConverter(JSONSpecFlagEnum).from_nason("2").should eq(JSONSpecFlagEnum::Two)
        Enum::ValueConverter(JSONSpecFlagEnum).from_nason("4").should eq(JSONSpecFlagEnum::OneHundred)
        Enum::ValueConverter(JSONSpecFlagEnum).from_nason("5").should eq(JSONSpecFlagEnum::OneHundred | JSONSpecFlagEnum::One)
        Enum::ValueConverter(JSONSpecFlagEnum).from_nason("7").should eq(JSONSpecFlagEnum::All)

        expect_raises(NASON::ParseException, %(Unknown enum JSONSpecFlagEnum value: 8)) do
          Enum::ValueConverter(JSONSpecFlagEnum).from_nason("8")
        end
        expect_raises(NASON::ParseException, %(Unknown enum JSONSpecFlagEnum value: -1)) do
          Enum::ValueConverter(JSONSpecFlagEnum).from_nason("-1")
        end
        expect_raises(NASON::ParseException, %(Expected Int but was String)) do
          Enum::ValueConverter(JSONSpecFlagEnum).from_nason(%(""))
        end
        expect_raises(NASON::ParseException, "Expected Int but was String") do
          Enum::ValueConverter(JSONSpecFlagEnum).from_nason(%("one"))
        end
        expect_raises(NASON::ParseException, "Expected Int but was BeginObject") do
          Enum::ValueConverter(JSONSpecFlagEnum).from_nason(%({}))
        end
        expect_raises(NASON::ParseException, "Expected Int but was BeginArray") do
          Enum::ValueConverter(JSONSpecFlagEnum).from_nason(%([]))
        end
      end
    end

    it "deserializes with root" do
      Int32.from_nason(%({"foo": 1}), root: "foo").should eq(1)
      Array(Int32).from_nason(%({"foo": [1, 2]}), root: "foo").should eq([1, 2])
    end

    it "deserializes union" do
      Array(Int32 | String).from_nason(%([1, "hello"])).should eq([1, "hello"])
    end

    it "deserializes union with bool (fast path)" do
      Union(Bool, Array(Int32)).from_nason(%(true)).should be_true
    end

    {% for type in %w(Int8 Int16 Int32 Int64 UInt8 UInt16 UInt32 UInt64).map(&.id) %}
        it "deserializes union with {{type}} (fast path)" do
          Union({{type}}, Array(Int32)).from_nason(%(#{ {{type}}::MAX })).should eq({{type}}::MAX)
        end
      {% end %}

    it "deserializes union with Float32 (fast path)" do
      Union(Float32, Array(Int32)).from_nason(%(1)).should eq(1)
      Union(Float32, Array(Int32)).from_nason(%(1.23)).should eq(1.23_f32)
    end

    it "deserializes union with Float64 (fast path)" do
      Union(Float64, Array(Int32)).from_nason(%(1)).should eq(1)
      Union(Float64, Array(Int32)).from_nason(%(1.23)).should eq(1.23)
    end

    it "deserializes union of Int32 and Float64 (#7333)" do
      value = Union(Int32, Float64).from_nason("1")
      value.should be_a(Int32)
      value.should eq(1)

      value = Union(Int32, Float64).from_nason("1.0")
      value.should be_a(Float64)
      value.should eq(1.0)
    end

    it "deserializes unions of the same kind and remains stable" do
      str = [Int32::MAX, Int64::MAX].to_nason
      value = Array(Int32 | Int64).from_nason(str)
      value.all? &.should be_a(Int64)
    end

    it "deserializes Time" do
      Time.from_nason(%("2016-11-16T09:55:48-03:00")).to_utc.should eq(Time.utc(2016, 11, 16, 12, 55, 48))
      Time.from_nason(%("2016-11-16T09:55:48-0300")).to_utc.should eq(Time.utc(2016, 11, 16, 12, 55, 48))
      Time.from_nason(%("20161116T095548-03:00")).to_utc.should eq(Time.utc(2016, 11, 16, 12, 55, 48))
    end

    describe "parse exceptions" do
      it "has correct location when raises in NamedTuple#from_nason" do
        ex = expect_raises(NASON::ParseException) do
          Array({foo: Int32, bar: String}).from_nason <<-NASON
            [
              {"foo": 1}
            ]
            NASON
        end
        ex.location.should eq({2, 3})
      end

      it "has correct location when raises in Union#from_nason" do
        ex = expect_raises(NASON::ParseException) do
          Array(Int32 | Bool).from_nason <<-NASON
            [
              {"foo": "bar"}
            ]
            NASON
        end
        ex.location.should eq({2, 3})
      end

      it "captures overflows for integer types" do
        ex = expect_raises(NASON::ParseException) do
          Array(Int32).from_nason <<-NASON
            [
              #{Int64::MAX.to_nason}
            ]
            NASON
        end
        ex.location.should eq({2, 3})
      end
    end
  end

  describe "to_nason" do
    it "does for Nil" do
      nil.to_nason.should eq("null")
    end

    it "does for Bool" do
      true.to_nason.should eq("true")
    end

    it "does for Int32" do
      1.to_nason.should eq("1")
    end

    it "does for Float64" do
      1.5.to_nason.should eq("1.5")
    end

    it "raises if Float is NaN" do
      expect_raises NASON::Error, "NaN not allowed in NASON" do
        (0.0/0.0).to_nason
      end
    end

    it "raises if Float is infinity" do
      expect_raises NASON::Error, "Infinity not allowed in NASON" do
        Float64::INFINITY.to_nason
      end
    end

    it "does for String" do
      "hello".to_nason.should eq("\"hello\"")
    end

    it "does for String with quote" do
      "hel\"lo".to_nason.should eq("\"hel\\\"lo\"")
    end

    it "does for String with slash" do
      "hel\\lo".to_nason.should eq("\"hel\\\\lo\"")
    end

    it "does for String with control codes" do
      "\b".to_nason.should eq("\"\\b\"")
      "\f".to_nason.should eq("\"\\f\"")
      "\n".to_nason.should eq("\"\\n\"")
      "\r".to_nason.should eq("\"\\r\"")
      "\t".to_nason.should eq("\"\\t\"")
      "\u{19}".to_nason.should eq("\"\\u0019\"")
    end

    it "does for String with control codes in a few places" do
      "\fab".to_nason.should eq(%q("\fab"))
      "ab\f".to_nason.should eq(%q("ab\f"))
      "ab\fcd".to_nason.should eq(%q("ab\fcd"))
      "ab\fcd\f".to_nason.should eq(%q("ab\fcd\f"))
      "ab\fcd\fe".to_nason.should eq(%q("ab\fcd\fe"))
      "\u{19}ab".to_nason.should eq(%q("\u0019ab"))
      "ab\u{19}".to_nason.should eq(%q("ab\u0019"))
      "ab\u{19}cd".to_nason.should eq(%q("ab\u0019cd"))
      "ab\u{19}cd\u{19}".to_nason.should eq(%q("ab\u0019cd\u0019"))
      "ab\u{19}cd\u{19}e".to_nason.should eq(%q("ab\u0019cd\u0019e"))
    end

    it "does for Path" do
      Path.posix("foo", "bar", "baz").to_nason.should eq(%("foo/bar/baz"))
      Path.windows("foo", "bar", "baz").to_nason.should eq(%("foo\\\\bar\\\\baz"))
    end

    it "does for Array" do
      [1, 2, 3].to_nason.should eq("[1,2,3]")
    end

    it "does for Deque" do
      Deque.new([1, 2, 3]).to_nason.should eq("[1,2,3]")
    end

    it "does for Set" do
      Set(Int32).new([1, 1, 2]).to_nason.should eq("[1,2]")
    end

    it "does for Hash" do
      {"foo" => 1, "bar" => 2}.to_nason.should eq(%({"foo":1,"bar":2}))
    end

    it "does for Hash with symbol keys" do
      {:foo => 1, :bar => 2}.to_nason.should eq(%({"foo":1,"bar":2}))
    end

    it "does for Hash with int keys" do
      {1 => 2, 3 => 6}.to_nason.should eq(%({"1":2,"3":6}))
    end

    it "does for Hash with Float32 keys" do
      {1.2_f32 => 2, 3.4_f32 => 6}.to_nason.should eq(%({"1.2":2,"3.4":6}))
    end

    it "does for Hash with Float64 keys" do
      {1.2 => 2, 3.4 => 6}.to_nason.should eq(%({"1.2":2,"3.4":6}))
    end

    it "does for Hash with newlines" do
      {"foo\nbar" => "baz\nqux"}.to_nason.should eq(%({"foo\\nbar":"baz\\nqux"}))
    end

    it "does for Tuple" do
      {1, "hello"}.to_nason.should eq(%([1,"hello"]))
    end

    it "does for NamedTuple" do
      {x: 1, y: "hello"}.to_nason.should eq(%({"x":1,"y":"hello"}))
    end

    describe "Enum" do
      it "normal enum" do
        JSONSpecEnum::One.to_nason.should eq %("one")
        JSONSpecEnum.from_nason(JSONSpecEnum::One.to_nason).should eq(JSONSpecEnum::One)

        JSONSpecEnum::OneHundred.to_nason.should eq %("one_hundred")
        JSONSpecEnum.from_nason(JSONSpecEnum::OneHundred.to_nason).should eq(JSONSpecEnum::OneHundred)

        # undefined members can't be parsed back because the standard converter only accepts named
        # members
        JSONSpecEnum.new(42).to_nason.should eq %("42")
      end

      it "flag enum" do
        JSONSpecFlagEnum::One.to_nason.should eq %(["one"])
        JSONSpecFlagEnum.from_nason(JSONSpecFlagEnum::One.to_nason).should eq(JSONSpecFlagEnum::One)

        JSONSpecFlagEnum::OneHundred.to_nason.should eq %(["one_hundred"])
        JSONSpecFlagEnum.from_nason(JSONSpecFlagEnum::OneHundred.to_nason).should eq(JSONSpecFlagEnum::OneHundred)

        combined = JSONSpecFlagEnum::OneHundred | JSONSpecFlagEnum::One
        combined.to_nason.should eq %(["one","one_hundred"])
        JSONSpecFlagEnum.from_nason(combined.to_nason).should eq(combined)

        JSONSpecFlagEnum::None.to_nason.should eq %([])
        JSONSpecFlagEnum.from_nason(JSONSpecFlagEnum::None.to_nason).should eq(JSONSpecFlagEnum::None)

        JSONSpecFlagEnum::All.to_nason.should eq %(["one","two","one_hundred"])
        JSONSpecFlagEnum.from_nason(JSONSpecFlagEnum::All.to_nason).should eq(JSONSpecFlagEnum::All)

        JSONSpecFlagEnum.new(42).to_nason.should eq %(["two"])
      end
    end

    describe "Enum::ValueConverter" do
      it "normal enum" do
        converter = Enum::ValueConverter(JSONSpecEnum)
        converter.to_nason(JSONSpecEnum::One).should eq %(1)
        converter.from_nason(converter.to_nason(JSONSpecEnum::One)).should eq(JSONSpecEnum::One)

        converter.to_nason(JSONSpecEnum::OneHundred).should eq %(3)
        converter.from_nason(converter.to_nason(JSONSpecEnum::OneHundred)).should eq(JSONSpecEnum::OneHundred)

        # undefined members can't be parsed back because the standard converter only accepts named
        # members
        converter.to_nason(JSONSpecEnum.new(42)).should eq %(42)
      end

      it "flag enum" do
        converter = Enum::ValueConverter(JSONSpecFlagEnum)
        converter.to_nason(JSONSpecFlagEnum::One).should eq %(1)
        converter.from_nason(converter.to_nason(JSONSpecFlagEnum::One)).should eq(JSONSpecFlagEnum::One)

        converter.to_nason(JSONSpecFlagEnum::OneHundred).should eq %(4)
        converter.from_nason(converter.to_nason(JSONSpecFlagEnum::OneHundred)).should eq(JSONSpecFlagEnum::OneHundred)

        combined = JSONSpecFlagEnum::OneHundred | JSONSpecFlagEnum::One
        converter.to_nason(combined).should eq %(5)
        converter.from_nason(converter.to_nason(combined)).should eq(combined)

        converter.to_nason(JSONSpecFlagEnum::None).should eq %(0)
        converter.from_nason(converter.to_nason(JSONSpecFlagEnum::None)).should eq(JSONSpecFlagEnum::None)

        converter.to_nason(JSONSpecFlagEnum::All).should eq %(7)
        converter.from_nason(converter.to_nason(JSONSpecFlagEnum::All)).should eq(JSONSpecFlagEnum::All)

        converter.to_nason(JSONSpecFlagEnum.new(42)).should eq %(42)
      end
    end

    it "does for UUID" do
      uuid = UUID.new("ee843b26-56d8-472b-b343-0b94ed9077ff")
      uuid.to_nason.should eq("\"ee843b26-56d8-472b-b343-0b94ed9077ff\"")
    end
  end

  describe "to_pretty_json" do
    it "does for Nil" do
      nil.to_pretty_json.should eq("null")
    end

    it "does for Bool" do
      true.to_pretty_json.should eq("true")
    end

    it "does for Int32" do
      1.to_pretty_json.should eq("1")
    end

    it "does for Float64" do
      1.5.to_pretty_json.should eq("1.5")
    end

    it "does for String" do
      "hello".to_pretty_json.should eq("\"hello\"")
    end

    it "does for Array" do
      [1, 2, 3].to_pretty_json.should eq("[\n  1,\n  2,\n  3\n]")
    end

    it "does for nested Array" do
      [[1, 2, 3]].to_pretty_json.should eq("[\n  [\n    1,\n    2,\n    3\n  ]\n]")
    end

    it "does for empty Array" do
      ([] of Nil).to_pretty_json.should eq("[]")
    end

    it "does for Hash" do
      {"foo" => 1, "bar" => 2}.to_pretty_json.should eq(%({\n  "foo": 1,\n  "bar": 2\n}))
    end

    it "does for nested Hash" do
      {"foo" => {"bar" => 1}}.to_pretty_json.should eq(%({\n  "foo": {\n    "bar": 1\n  }\n}))
    end

    it "does for empty Hash" do
      ({} of Nil => Nil).to_pretty_json.should eq(%({}))
    end

    it "does for Array with indent" do
      [1, 2, 3].to_pretty_json(indent: " ").should eq("[\n 1,\n 2,\n 3\n]")
    end

    it "does for nested Hash with indent" do
      {"foo" => {"bar" => 1}}.to_pretty_json(indent: " ").should eq(%({\n "foo": {\n  "bar": 1\n }\n}))
    end

    describe "Time" do
      it "#to_nason" do
        Time.utc(2016, 11, 16, 12, 55, 48).to_nason.should eq(%("2016-11-16T12:55:48Z"))
        Time.local(2016, 11, 16, 12, 55, 48, location: Time::Location.fixed(7200)).to_nason.should eq(%("2016-11-16T12:55:48+02:00"))
      end

      it "omit sub-second precision" do
        Time.utc(2016, 11, 16, 12, 55, 48, nanosecond: 123456789).to_nason.should eq(%("2016-11-16T12:55:48Z"))
      end
    end
  end

  it "provide symmetric encoding and decoding for Union types" do
    a = 1.as(Float64 | Int32)
    b = (Float64 | Int32).from_nason(a.to_nason)
    a.class.should eq(Int32)
    a.class.should eq(b.class)

    c = 1.0.as(Float64 | Int32)
    d = (Float64 | Int32).from_nason(c.to_nason)
    c.class.should eq(Float64)
    c.class.should eq(d.class)
  end
end
