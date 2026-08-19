class SourcesController < ApplicationController
  before_action :set_project

  def index
    @sources = @project.sources.order(:name)
    @source = @project.sources.new(source_type: "http", status: "active", environment: @project.environment)
  end

  def create
    @source = @project.sources.new(source_params)

    if @source.save
      redirect_to project_sources_path(@project), notice: "Source created."
    else
      @sources = @project.sources.order(:name)
      flash.now[:alert] = @source.errors.full_messages.to_sentence
      render :index, status: :unprocessable_entity
    end
  end

  private

  def set_project
    @project = load_project(params[:project_id], minimum_role: :admin)
  end

  def source_params
    params.expect(source: %i[name slug source_type environment description status]).to_h.symbolize_keys
  end
end
