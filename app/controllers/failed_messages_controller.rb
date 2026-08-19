class FailedMessagesController < ApplicationController
  before_action :set_project
  before_action :set_investigation

  def index
    @sources = @project.sources.order(:name)
    @failed_messages = @investigation.inbox(filter_params)
  end

  def show
    @detail = @investigation.detail(params[:id])
  end

  def update_status
    detail = @investigation.change_status(id: params[:id], status: params[:status])
    redirect_to project_failed_message_path(@project, detail.failed_message), notice: "Message status updated."
  rescue ActiveRecord::RecordInvalid => error
    @detail = @investigation.detail(params[:id])
    flash.now[:alert] = error.record.errors.full_messages.to_sentence
    render :show, status: :unprocessable_entity
  end

  private

  def set_project
    minimum_role = :operator unless action_name.in?(%w[index show])
    @project = load_project(params[:project_id], minimum_role: minimum_role)
  end

  def set_investigation
    @investigation = FailedMessages::Investigation.new(project: @project, actor: current_user)
  end

  def filter_params
    params.permit(
      :status,
      :source_id,
      :queue_name,
      :event_type,
      :failure_type,
      :fingerprint,
      :correlation_id,
      :latest_replay_status,
      :date_from,
      :date_to
    ).to_h.symbolize_keys
  end
end
