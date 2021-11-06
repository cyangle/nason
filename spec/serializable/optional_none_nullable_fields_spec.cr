require "../spec_helper"

class OLocation
  include NASON::Serializable

  @[NASON::Field(key: "lat")]
  property latitude : Float64?

  @[NASON::Field(key: "lng")]
  property longitude : Float64?

  def initialize(@latitude = nil, @longitude = nil)
  end
end

describe NASON do
  it "should parse all values" do
    json_string = %({"lat":1.2,"lng":2.2})
    l = OLocation.from_json(json_string)
    l.latitude.should eq 1.2_f64
    l.longitude.should eq 2.2_f64
    l.to_json.should eq json_string
  end

  it "should not parse null" do
    expect_raises(NASON::SerializableError, "Expecting none null value but got null") do
      l = OLocation.from_json(%({"lat":1.2,"lng":null}))
    end
  end

  it "should parse empty object" do
    json_string = %({})
    l = OLocation.from_json(json_string)
    l.latitude.should be_nil
    l.longitude.should be_nil
    l.to_json.should eq json_string
  end

  it "should parse object with some keys" do
    json_string = %({"lng":1.2})
    l = OLocation.from_json(json_string)
    l.latitude.should be_nil
    l.longitude.should eq 1.2_f64
    l.to_json.should eq json_string
  end
end
