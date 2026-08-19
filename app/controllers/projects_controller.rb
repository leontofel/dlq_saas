class ProjectsController < ApplicationController
  before_action :set_organization_from_params, only: %i[index create]
  before_action :set_project, only: :show

  def index
    @projects = @organization.projects.order(:name)
  end

  def show
    @project_api_keys = @project.project_api_keys.order(created_at: :desc) if current_membership.at_least?(:admin)
  end

  def create
    result = Projects::Create.call(
      organization: @organization,
      attributes: project_params
    )

    if result.success?
      redirect_to project_path(result.project), notice: "Project created."
    else
      @projects = @organization.projects.order(:name)
      flash.now[:alert] = result.error
      render :index, status: :unprocessable_entity
    end
  end

  private

  def set_organization_from_params
    minimum_role = :admin if action_name == "create"
    @organization = load_organization(params[:organization_id], minimum_role: minimum_role)
  end

  def set_project
    @project = load_project(params[:id])
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
