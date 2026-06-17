module ProjectApiKeys
  class Revoke < ApplicationService
    Result = Struct.new(
      :success?,
      :project_api_key,
      :error,
      keyword_init: true
    )

    def initialize(project_api_key:)
      @project_api_key = project_api_key
    end

    def call
      @project_api_key.update(revoked_at: Time.current)

      Result.new(success?: @project_api_key.errors.empty?, project_api_key: @project_api_key,
                 error: @project_api_key.errors.full_messages.to_sentence.presence)
    end
  end
end
