class ProjectsController < ApplicationController
  before_action :set_organization_from_params, only: %i[index create]
  before_action :set_project, only: :show

  def index
    set_current_organization(@organization)
    @projects = @organization.projects.order(:name)
  end

  def show
    set_current_project(@project)
    @project_api_keys = @project.project_api_keys.order(created_at: :desc)
  end

  def create
    return unless require_organization_role!(@organization, :admin).nil?

    result = Projects::Create.call(
      organization: @organization,
      attributes: project_params
    )

    if result.success?
      redirect_to project_path(result.project), notice: "Project created."
    else
      set_current_organization(@organization)
      @projects = @organization.projects.order(:name)
      flash.now[:alert] = result.error
      render :index, status: :unprocessable_entity
    end
  end

  private

  def set_organization_from_params
    @organization = Organization.visible_to(current_user).find(params[:organization_id])
  end

  def set_project
    @project = Project.joins(:organization)
                      .merge(Organization.visible_to(current_user))
                      .find(params[:id])
  end

  def project_params
    attrs = params.expect(
      project: %i[
        name
        slug
        environment
        status
        default_retention_days
        max_payload_size_bytes
        default_replay_policy
        allowed_source_identifiers
      ]
    ).to_h.symbolize_keys

    attrs[:default_retention_days] = attrs[:default_retention_days].to_i if attrs[:default_retention_days].present?
    attrs[:max_payload_size_bytes] = attrs[:max_payload_size_bytes].to_i if attrs[:max_payload_size_bytes].present?
    attrs
  end
end
