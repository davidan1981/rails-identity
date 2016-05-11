require 'test_helper'

class RailsIdentityTest < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, RailsIdentity
  end

  test "basic cache operations" do
    RailsIdentity::Cache.set("foo", 42)
    assert_equal 42, RailsIdentity::Cache.get("foo")
  end
end
