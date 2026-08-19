class RedactionRulesController < ApplicationController
  before_action :set_project

  def index
    @redaction_rules = @project.redaction_rules.order(:json_path)
    @redaction_rule = @project.redaction_rules.new(status: "active", replacement: "[REDACTED]")
  end

  def create
    @redaction_rule = @project.redaction_rules.new(redaction_rule_params)

    if @redaction_rule.save
      redirect_to project_redaction_rules_path(@project), notice: "Redaction rule created."
    else
      @redaction_rules = @project.redaction_rules.order(:json_path)
      flash.now[:alert] = @redaction_rule.errors.full_messages.to_sentence
      render :index, status: :unprocessable_entity
    end
  end

  private

  def set_project
    @project = load_project(params[:project_id], minimum_role: :admin)
  end

  def redaction_rule_params
    params.expect(redaction_rule: %i[json_path replacement status]).to_h.symbolize_keys
  end
end
