require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "normalizes slug and source identifiers" do
    organization = create_organization
    project = Project.new(
      organization: organization,
      name: "Replay Console",
      slug: "Replay Console",
      environment: "production",
      status: "active",
      default_retention_days: 30,
      max_payload_size_bytes: 1000,
      default_replay_policy: "manual_allowed"
    )
    project.allowed_source_identifiers = [ " source-a ", "source-a", "source-b" ]

    assert project.valid?
    assert_equal "replay-console", project.slug
    assert_equal %w[source-a source-b], project.allowed_source_identifiers
  end

  test "destroys failed messages before their restricted source" do
    tenant = create_tenant
    project = tenant.fetch(:project)
    source = create_source(project: project)
    create_failed_message(project: project, source: source)

    assert_difference([ "Project.count", "Source.count", "FailedMessage.count" ], -1) do
      project.destroy!
    end
  end
end
