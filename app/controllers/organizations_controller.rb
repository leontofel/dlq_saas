class OrganizationsController < ApplicationController
  before_action :set_organization, only: :show

  def index
    @organizations = Organization.visible_to(current_user)
                                 .includes(:projects, :organization_memberships)
                                 .order(:name)
  end

  def show
    set_current_organization(@organization)
    @projects = @organization.projects.order(:name)
    @memberships = @organization.organization_memberships.includes(:user).order(:created_at)
  end

  def create
    result = Organizations::Create.call(**organization_create_params.merge(user: current_user))

    if result.success?
      redirect_to organization_path(result.organization), notice: "Organization created."
    else
      @organizations = Organization.visible_to(current_user).order(:name)
      flash.now[:alert] = result.error
      render :index, status: :unprocessable_entity
    end
  end

  private

  def set_organization
    @organization = Organization.visible_to(current_user).find(params[:id])
  end

  def organization_create_params
    params.expect(organization: %i[name slug]).to_h.symbolize_keys
  end
end
