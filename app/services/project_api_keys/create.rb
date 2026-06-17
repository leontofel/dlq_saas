require "securerandom"

module ProjectApiKeys
  class Create < ApplicationService
    Result = Struct.new(
      :success?,
      :project_api_key,
      :raw_key,
      :error,
      keyword_init: true
    )

    def initialize(project:, created_by_user:, name:, scopes:)
      @project = project
      @created_by_user = created_by_user
      @name = name
      @scopes = scopes
    end

    def call
      raw_key = build_raw_key
      project_api_key = @project.project_api_keys.new(
        created_by_user: @created_by_user,
        name: @name,
        key_prefix: raw_key.first(18),
        key_digest: ProjectApiKey.digest(raw_key)
      )
      project_api_key.scopes = @scopes

      return failure(project_api_key.errors.full_messages.to_sentence) unless project_api_key.save

      Result.new(success?: true, project_api_key: project_api_key, raw_key: raw_key)
    end

    private

    def build_raw_key
      "dlq_live_#{SecureRandom.hex(24)}"
    end

    def failure(message)
      Result.new(success?: false, error: message)
    end
  end
end
