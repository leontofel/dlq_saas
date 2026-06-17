module Organizations
  class Create < ApplicationService
    Result = Struct.new(
      :success?,
      :organization,
      :membership,
      :error,
      keyword_init: true
    )

    def initialize(user:, name:, slug:)
      @user = user
      @name = name
      @slug = slug
    end

    def call
      organization = Organization.new(
        name: @name,
        slug: @slug.presence || @name
      )

      return failure(organization.errors.full_messages.to_sentence) unless organization.valid?

      membership = nil

      Organization.transaction do
        organization.save!
        membership = organization.organization_memberships.create!(
          user: @user,
          role: "owner"
        )
      end

      Result.new(success?: true, organization: organization, membership: membership)
    rescue ActiveRecord::RecordInvalid => error
      failure(error.record.errors.full_messages.to_sentence)
    end

    private

    def failure(message)
      Result.new(success?: false, error: message)
    end
  end
end
