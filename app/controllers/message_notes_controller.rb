class MessageNotesController < ApplicationController
  before_action :set_project
  before_action :set_investigation

  def create
    detail = @investigation.add_note(id: params[:failed_message_id], body: message_note_params.fetch(:body))
    redirect_to project_failed_message_path(@project, detail.failed_message), notice: "Note added."
  rescue ActiveRecord::RecordInvalid => error
    @detail = @investigation.detail(params[:failed_message_id], message_note: error.record)
    flash.now[:alert] = error.record.errors.full_messages.to_sentence
    render "failed_messages/show", status: :unprocessable_entity
  end

  private

  def set_project
    @project = load_project(params[:project_id], minimum_role: :operator)
  end

  def set_investigation
    @investigation = FailedMessages::Investigation.new(project: @project, actor: current_user)
  end

  def message_note_params
    params.expect(message_note: %i[body]).to_h.symbolize_keys
  end
end
