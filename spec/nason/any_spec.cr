require "../spec_helper"
require "yaml"

describe NASON::Any do
  describe "casts" do
    it "gets nil" do
      NASON.parse("null").as_null.should eq NULL
    end

    it "gets bool" do
      NASON.parse("true").as_bool.should be_true
      NASON.parse("false").as_bool.should be_false
      NASON.parse("true").as_bool?.should be_true
      NASON.parse("false").as_bool?.should be_false
      NASON.parse("2").as_bool?.should be_nil
    end

    it "gets int32" do
      NASON.parse("123").as_i.should eq(123)
      NASON.parse("123").as_i?.should eq(123)
      NASON.parse("true").as_i?.should be_nil
    end

    it "gets int64" do
      NASON.parse("123456789123456").as_i64.should eq(123456789123456)
      NASON.parse("123456789123456").as_i64?.should eq(123456789123456)
      NASON.parse("true").as_i64?.should be_nil
    end

    it "gets float32" do
      NASON.parse("123.45").as_f32.should eq(123.45_f32)
      NASON.parse("123.45").as_f32?.should eq(123.45_f32)
      NASON.parse("true").as_f32?.should be_nil
    end

    it "gets float64" do
      NASON.parse("123.45").as_f.should eq(123.45)
      NASON.parse("123.45").as_f?.should eq(123.45)
      NASON.parse("true").as_f?.should be_nil
    end

    it "gets string" do
      NASON.parse(%("hello")).as_s.should eq("hello")
      NASON.parse(%("hello")).as_s?.should eq("hello")
      NASON.parse("true").as_s?.should be_nil
    end

    it "gets array" do
      NASON.parse(%([1, 2, 3])).as_a.should eq([1, 2, 3])
      NASON.parse(%([1, 2, 3])).as_a?.should eq([1, 2, 3])
      NASON.parse("true").as_a?.should be_nil
    end

    it "gets hash" do
      NASON.parse(%({"foo": "bar"})).as_h.should eq({"foo" => "bar"})
      NASON.parse(%({"foo": "bar"})).as_h?.should eq({"foo" => "bar"})
      NASON.parse("true").as_h?.should be_nil
    end
  end

  describe "#size" do
    it "of array" do
      NASON.parse("[1, 2, 3]").size.should eq(3)
    end

    it "of hash" do
      NASON.parse(%({"foo": "bar"})).size.should eq(1)
    end
  end

  describe "#[]" do
    it "of array" do
      NASON.parse("[1, 2, 3]")[1].raw.should eq(2)
    end

    it "of hash" do
      NASON.parse(%({"foo": "bar"}))["foo"].raw.should eq("bar")
    end
  end

  describe "#[]?" do
    it "of array" do
      NASON.parse("[1, 2, 3]")[1]?.not_nil!.raw.should eq(2)
      NASON.parse("[1, 2, 3]")[3]?.should be_nil
      NASON.parse("[true, false]")[1]?.should eq false
    end

    it "of hash" do
      NASON.parse(%({"foo": "bar"}))["foo"]?.not_nil!.raw.should eq("bar")
      NASON.parse(%({"foo": "bar"}))["fox"]?.should be_nil
      NASON.parse(%q<{"foo": false}>)["foo"]?.should eq false
    end
  end

  describe "#dig?" do
    it "gets the value at given path given splat" do
      obj = NASON.parse(%({"foo": [1, {"bar": [2, 3]}]}))

      obj.dig?("foo", 0).should eq(1)
      obj.dig?("foo", 1, "bar", 1).should eq(3)
    end

    it "returns nil if not found" do
      obj = NASON.parse(%({"foo": [1, {"bar": [2, 3]}]}))

      obj.dig?("foo", 10).should be_nil
      obj.dig?("bar", "baz").should be_nil
      obj.dig?("").should be_nil
    end

    it "returns nil for non-Hash/Array intermediary values" do
      NASON::Any.new(nil).dig?("foo").should be_nil
      NASON::Any.new(0.0).dig?("foo").should be_nil
    end
  end

  describe "dig" do
    it "gets the value at given path given splat" do
      obj = NASON.parse(%({"foo": [1, {"bar": [2, 3]}]}))

      obj.dig("foo", 0).should eq(1)
      obj.dig("foo", 1, "bar", 1).should eq(3)
    end

    it "raises if not found" do
      obj = NASON.parse(%({"foo": [1, {"bar": [2, 3]}]}))

      expect_raises Exception, %(Expected Hash for #[](key : String), not Array(NASON::Any)) do
        obj.dig("foo", 1, "bar", "baz")
      end
      expect_raises KeyError, %(Missing hash key: "z") do
        obj.dig("z")
      end
      expect_raises KeyError, %(Missing hash key: "") do
        obj.dig("")
      end
    end
  end

  it "traverses big structure" do
    obj = NASON.parse(%({"foo": [1, {"bar": [2, 3]}]}))
    obj["foo"][1]["bar"][1].as_i.should eq(3)
  end

  it "compares to other objects" do
    obj = NASON.parse(%([1, 2]))
    obj.should eq([1, 2])
    obj[0].should eq(1)
  end

  it "can compare with ===" do
    (1 === NASON.parse("1")).should be_truthy
  end

  it "exposes $~ when doing Regex#===" do
    (/o+/ === NASON.parse(%("foo"))).should be_truthy
    $~[0].should eq("oo")
  end

  it "dups" do
    any = NASON.parse("[1, 2, 3]")
    any2 = any.dup
    any2.as_a.should_not be(any.as_a)
  end

  it "clones" do
    any = NASON.parse("[[1], 2, 3]")
    any2 = any.clone
    any2.as_a[0].as_a.should_not be(any.as_a[0].as_a)
  end

  it "#to_yaml" do
    any = NASON.parse <<-NASON
      {
        "foo": "bar",
        "baz": [1, 2.3, true, "qux", {"qax": "qox"}]
      }
      NASON
    any.to_yaml.should eq <<-YAML
      ---
      foo: bar
      baz:
      - 1
      - 2.3
      - true
      - qux
      - qax: qox

      YAML
  end
end
