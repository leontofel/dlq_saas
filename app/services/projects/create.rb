module Projects
  class Create < ApplicationService
    Result = Struct.new(
      :success?,
      :project,
      :error,
      keyword_init: true
    )

    def initialize(organization:, attributes:)
      @organization = organization
      @attributes = attributes
    end

    def call
      project = @organization.projects.new(filtered_attributes)

      return failure(project.errors.full_messages.to_sentence) unless project.save

      Result.new(success?: true, project: project)
    end

    private

    def filtered_attributes
      @attributes.slice(
        :name,
        :slug,
        :environment,
        :status,
        :default_retention_days,
        :max_payload_size_bytes,
        :default_replay_policy,
        :allowed_source_identifiers
      )
    end

    def failure(message)
      Result.new(success?: false, error: message)
    end
  end
end
