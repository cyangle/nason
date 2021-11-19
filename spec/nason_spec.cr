require "./spec_helper"

describe NASON do
  # TODO: Write tests

  it "has correct version number" do
    NASON::VERSION.should eq("0.2.3")
  end

  it "parses null value" do
    obj = NASON.parse(%({"name": null}))
    obj["name"].as_null.should eq NULL
    obj["name"].as_null.null?.should eq true
    obj["name"].as_null.nil_or_null?.should eq true
    obj["name"].as_null.to_s.should eq "null"
  end

  it "builds" do
    obj = NASON.build do |json|
      json.object do
        json.field "name", NULL
        json.field "values" do
          json.array do
            json.null
            json.null
            json.null
          end
        end
      end
    end
    obj.to_s.should eq %({"name":null,"values":[null,null,null]})
  end
end
