class ProjectApiKeysController < ApplicationController
  before_action :set_project, only: :create
  before_action :set_project_api_key, only: :revoke

  def create
    return unless require_organization_role!(@project.organization, :operator).nil?

    result = ProjectApiKeys::Create.call(
      project: @project,
      created_by_user: current_user,
      name: project_api_key_params.fetch(:name),
      scopes: Array(project_api_key_params[:scopes]).reject(&:blank?)
    )

    if result.success?
      flash[:new_api_key_secret] = result.raw_key
      redirect_to project_path(@project), notice: "API key created. Copy the secret now."
    else
      set_current_project(@project)
      @project_api_keys = @project.project_api_keys.order(created_at: :desc)
      flash.now[:alert] = result.error
      render "projects/show", status: :unprocessable_entity
    end
  end

  def revoke
    return unless require_organization_role!(@project_api_key.project.organization, :operator).nil?

    ProjectApiKeys::Revoke.call(project_api_key: @project_api_key)
    redirect_to project_path(@project_api_key.project), notice: "API key revoked."
  end

  private

  def set_project
    @project = Project.joins(:organization)
                      .merge(Organization.visible_to(current_user))
                      .find(params[:project_id])
  end

  def set_project_api_key
    @project_api_key = ProjectApiKey.joins(project: :organization)
                                    .merge(Organization.visible_to(current_user))
                                    .find(params[:id])
  end

  def project_api_key_params
    params.expect(project_api_key: [ :name, { scopes: [] } ]).to_h.symbolize_keys
  end
end
