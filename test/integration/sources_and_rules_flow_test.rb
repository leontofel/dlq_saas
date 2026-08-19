require "test_helper"

class SourcesAndRulesFlowTest < ActionDispatch::IntegrationTest
  test "admin can create a source and a redaction rule" do
    tenant = create_tenant(role: "admin")
    project = tenant.fetch(:project)
    sign_in_as(tenant.fetch(:user))

    assert_difference("Source.count", 1) do
      post project_sources_path(project),
           params: {
             source: {
               name: "Refund Worker",
               slug: "refund-worker",
               source_type: "http",
               environment: "production",
               description: "refund failures",
               status: "active"
             }
           },
           headers: modern_browser_headers
    end

    assert_redirected_to project_sources_path(project)

    assert_difference("RedactionRule.count", 1) do
      post project_redaction_rules_path(project),
           params: {
             redaction_rule: {
               json_path: "$.payment.card",
               replacement: "[HIDDEN]",
               status: "active"
             }
           },
           headers: modern_browser_headers
    end

    assert_redirected_to project_redaction_rules_path(project)
  end

  test "operator cannot manage sources or rules" do
    tenant = create_tenant(role: "operator")
    project = tenant.fetch(:project)
    sign_in_as(tenant.fetch(:user))

    get project_sources_path(project), headers: modern_browser_headers
    assert_response :forbidden

    assert_no_difference("RedactionRule.count") do
      post project_redaction_rules_path(project),
           params: {
             redaction_rule: {
               json_path: "$.blocked",
               replacement: "[X]",
               status: "active"
             }
           },
           headers: modern_browser_headers
    end

    assert_response :forbidden
  end
end
