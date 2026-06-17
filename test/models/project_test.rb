require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  fixtures :projects, :organizations

  test "normalizes slug and source identifiers" do
    project = Project.new(
      organization: organizations(:acme),
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
end
