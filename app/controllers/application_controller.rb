class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :authenticate_user!

  helper_method :current_user, :signed_in?, :current_organization, :current_project

  private

  def authenticate_user!
    return if signed_in?

    redirect_to login_page_path, alert: "Please sign in to continue."
  end

  def current_user
    @current_user ||= User.active.find_by(id: session[:user_id]) if session[:user_id].present?
  end

  def signed_in?
    current_user.present?
  end

  def current_organization
    @current_organization
  end

  def current_project
    @current_project
  end

  def set_current_organization(organization)
    @current_organization = organization
  end

  def set_current_project(project)
    @current_project = project
    @current_organization = project.organization
  end

  def require_organization_role!(organization, minimum_role)
    membership = current_user.membership_for(organization)

    if membership.blank?
      raise ActiveRecord::RecordNotFound
    end

    return if membership.at_least?(minimum_role)

    render_forbidden
  end

  def render_forbidden
    render plain: "Forbidden", status: :forbidden
  end
end
