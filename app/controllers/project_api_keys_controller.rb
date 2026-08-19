class ProjectApiKeysController < ApplicationController
  before_action :set_project
  before_action :set_project_api_key, only: :revoke

  def create
    result = ProjectApiKeys::Lifecycle.issue(
      project: @project,
      actor: current_user,
      name: project_api_key_params.fetch(:name),
      scopes: Array(project_api_key_params[:scopes]).reject(&:blank?)
    )

    if result.project_api_key.persisted?
      flash[:new_api_key_secret] = result.raw_key
      redirect_to project_path(@project), notice: "API key created. Copy the secret now."
    end
  rescue ActiveRecord::RecordInvalid => error
    @project_api_keys = @project.project_api_keys.order(created_at: :desc)
    flash.now[:alert] = error.record.errors.full_messages.to_sentence
    render "projects/show", status: :unprocessable_entity
  end

  def revoke
    ProjectApiKeys::Lifecycle.revoke(@project_api_key)
    redirect_to project_path(@project_api_key.project), notice: "API key revoked."
  end

  private

  def set_project
    @project = load_project(params[:project_id], minimum_role: :admin)
  end

  def set_project_api_key
    @project_api_key = @project.project_api_keys.find(params[:id])
  end

  def project_api_key_params
    params.expect(project_api_key: [ :name, { scopes: [] } ]).to_h.symbolize_keys
  end
end
