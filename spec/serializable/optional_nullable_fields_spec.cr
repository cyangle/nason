require "../spec_helper"

class ONLocation
  include NASON::Serializable

  @[NASON::Field(key: "lat")]
  property latitude : Float64? | Null

  @[NASON::Field(key: "lng")]
  property longitude : Float64? | Null

  def initialize(@latitude = nil, @longitude = nil)
  end
end

describe NASON do
  it "parses null values" do
    json_string = %({"lat":null})
    l = ONLocation.from_nason(json_string)
    l.latitude.should eq NULL
    l.longitude.should eq nil
    l.to_nason.should eq json_string
  end

  context "deserialize then serialize" do
    it "works with empty object" do
      json_string = "{}"
      l = ONLocation.from_nason(json_string)
      l.latitude.should eq nil
      l.longitude.should eq nil
      l.to_nason.should eq json_string
    end

    it "works with null value" do
      json_string = %({"lat":null})
      l = ONLocation.from_nason(json_string)
      l.latitude.should eq NULL
      l.longitude.should eq nil
      l.to_nason.should eq json_string
    end

    it "works with none null value" do
      json_string = %({"lat":1.2})
      l = ONLocation.from_nason(json_string)
      l.latitude.should eq 1.2_f64
      l.longitude.should eq nil
      l.to_nason.should eq json_string
    end

    it "works with mixed value" do
      json_string = %({"lat":1.2,"lng":null})
      l = ONLocation.from_nason(json_string)
      l.latitude.should eq 1.2_f64
      l.longitude.should eq NULL
      l.to_nason.should eq json_string
    end

    it "works with all null values" do
      json_string = %({"lat":null,"lng":null})
      l = ONLocation.from_nason(json_string)
      l.latitude.should eq NULL
      l.longitude.should eq NULL
      l.to_nason.should eq json_string
    end

    it "works with all none null values" do
      json_string = %({"lat":1.2,"lng":2.2})
      l = ONLocation.from_nason(json_string)
      l.latitude.should eq 1.2_f64
      l.longitude.should eq 2.2_f64
      l.to_nason.should eq json_string
    end
  end
end
