module OrganizationMemberships
  class Create < ApplicationService
    Result = Struct.new(
      :success?,
      :membership,
      :error,
      keyword_init: true
    )

    def initialize(organization:, email:, role:)
      @organization = organization
      @email = email
      @role = role
    end

    def call
      user = User.find_by(email: normalized_email)
      return failure("User not found for #{@email}") unless user

      membership = @organization.organization_memberships.new(
        user: user,
        role: @role
      )

      return failure(membership.errors.full_messages.to_sentence) unless membership.save

      Result.new(success?: true, membership: membership)
    end

    private

    def normalized_email
      @email.to_s.strip.downcase
    end

    def failure(message)
      Result.new(success?: false, error: message)
    end
  end
end
