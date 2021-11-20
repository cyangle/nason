require "../spec_helper"

class RNLocation
  include NASON::Serializable

  @[NASON::Field(key: "lat")]
  property latitude : Float64 | Null

  @[NASON::Field(key: "lng")]
  property longitude : Float64 | Null

  def initialize(@latitude = NULL, @longitude = NULL)
  end
end

describe NASON do
  it "allows none null values for all required properties" do
    json_string = %({"lat":1.2,"lng":2.2})
    l = RNLocation.from_nason(json_string)
    l.latitude.should eq 1.2_f64
    l.longitude.should eq 2.2_f64
    l.to_nason.should eq json_string
  end

  it "allows null values for required properties" do
    json_string = %({"lat":1.2,"lng":null})
    l = RNLocation.from_nason(json_string)
    l.latitude.should eq 1.2_f64
    l.longitude.should eq NULL
    l.to_nason.should eq json_string
  end

  it "requires fields" do
    expect_raises(NASON::SerializableError, "Missing JSON attribute: lng") do
      RNLocation.from_nason(%({"lat": 1.2}))
    end
  end

  it "requires fields" do
    expect_raises(NASON::SerializableError, "Missing JSON attribute: lng") do
      RNLocation.from_nason(%({"lat": null}))
    end
  end

  context "all nullable required fields with null values" do
    it "should work fine" do
      json_string = %({"lat":null,"lng":null})
      l = RNLocation.from_nason(json_string)
      l.latitude.should eq NULL
      l.longitude.should eq NULL
      l.to_nason.should eq json_string
    end
  end
end
