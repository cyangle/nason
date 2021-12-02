require "../spec_helper"

describe Null do
  describe "#null?" do
    it "returns true for NULL" do
      NULL.null?.should eq true
    end

    it "returns false for nil" do
      nil.null?.should eq false
    end

    it "returns false for string" do
      "test".null?.should eq false
    end
  end

  describe "#nil?" do
    it "returns false for for NULL" do
      NULL.nil?.should eq false
    end
  end

  describe "#nil_or_null?" do
    it "returns true for NULL" do
      NULL.nil_or_null?.should eq true
    end

    it "returns true for nil" do
      nil.nil_or_null?.should eq true
    end

    it "returns false for string" do
      "test".nil_or_null?.should eq false
    end
  end
end
