require "test_helper"

class RedactionRuleTest < ActiveSupport::TestCase
  test "accepts only the supported JSON path subset" do
    project = create_tenant.fetch(:project)

    payload_path = project.redaction_rules.new(json_path: "customer.cards[0].number", replacement: "[HIDDEN]")
    metadata_path = project.redaction_rules.new(json_path: "metadata.access_token", replacement: "[HIDDEN]")
    invalid = project.redaction_rules.new(json_path: "customer..number", replacement: "[HIDDEN]")

    assert payload_path.valid?
    assert metadata_path.valid?
    assert_not invalid.valid?
    assert_includes invalid.errors[:json_path], "must use dot keys and numeric indexes"
  end
end
