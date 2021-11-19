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

  describe "#present?" do
    it "returns true for NULL" do
      NULL.present?.should eq false
    end

    it "returns true for nil" do
      nil.present?.should eq false
    end

    it "returns false for empty string" do
      "".present?.should eq true
    end

    it "returns false for empty array" do
      Array(String).new.present?.should eq true
    end
  end

  describe "#present!" do
    it "raises NullAssertionError for NULL" do
      expect_raises NullAssertionError, "Null assertion failed" do
        NULL.present!
      end
    end

    it "returns NilAssertionError for nil" do
      expect_raises NilAssertionError, "Nil assertion failed" do
        nil.present!
      end
    end

    it "returns self for empty string" do
      "".present!.should eq ""
    end

    it "returns self for empty array" do
      Array(String).new.present!.should eq Array(String).new
    end
  end
end
