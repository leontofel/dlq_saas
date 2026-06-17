class OrganizationMembershipsController < ApplicationController
  before_action :set_organization

  def create
    return unless require_organization_role!(@organization, :admin).nil?

    result = OrganizationMemberships::Create.call(
      organization: @organization,
      email: membership_params.fetch(:email),
      role: membership_params.fetch(:role)
    )

    if result.success?
      redirect_to organization_path(@organization), notice: "Member added."
    else
      set_current_organization(@organization)
      @projects = @organization.projects.order(:name)
      @memberships = @organization.organization_memberships.includes(:user).order(:created_at)
      flash.now[:alert] = result.error
      render "organizations/show", status: :unprocessable_entity
    end
  end

  private

  def set_organization
    @organization = Organization.visible_to(current_user).find(params[:organization_id])
  end

  def membership_params
    params.expect(organization_membership: %i[email role]).to_h.symbolize_keys
  end
end
