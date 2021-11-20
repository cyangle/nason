require "../spec_helper"

class Location
  include NASON::Serializable

  # @[NASON::Field(key: "lat", nilable: true)]
  property lat : Float64

  # @[NASON::Field(key: "lng", nilable: true)]
  property lng : Float64

  def initialize(@lat, @lng)
  end
end

describe NASON do
  it "parses all values" do
    json_string = %({"lat":1.2,"lng":2.2})
    l = Location.from_nason(json_string)
    l.lat.should eq 1.2_f64
    l.lng.should eq 2.2_f64
    l.to_nason.should eq json_string
  end

  it "should not parse null" do
    expect_raises(NASON::SerializableError, "Expecting none null value but got null") do
      Location.from_nason(%({"lat":1.2,"lng":null}))
    end
  end

  it "should not parse nulls" do
    expect_raises(NASON::SerializableError, "Expecting none null value but got null") do
      Location.from_nason(%({"lat":null,"lng":null}))
    end
  end

  it "should not parse empty object" do
    expect_raises(NASON::SerializableError, "Missing JSON attribute: lat") do
      Location.from_nason(%({}))
    end
  end

  it "should not parse missing keys" do
    json_string = %({"lat":1.2})
    expect_raises(NASON::SerializableError, "Missing JSON attribute: lng") do
      Location.from_nason(json_string)
    end
  end
end
