class OrganizationMembershipsController < ApplicationController
  before_action :set_organization

  def create
    result = OrganizationMemberships::Create.call(
      organization: @organization,
      email: membership_params.fetch(:email),
      role: membership_params.fetch(:role)
    )

    if result.success?
      redirect_to organization_path(@organization), notice: "Member added."
    else
      @projects = @organization.projects.order(:name)
      @memberships = @organization.organization_memberships.includes(:user).order(:created_at)
      flash.now[:alert] = result.error
      render "organizations/show", status: :unprocessable_entity
    end
  end

  private

  def set_organization
    @organization = load_organization(params[:organization_id], minimum_role: :admin)
  end

  def membership_params
    params.expect(organization_membership: %i[email role]).to_h.symbolize_keys
  end
end
