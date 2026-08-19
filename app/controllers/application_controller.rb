class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :authenticate_identity!

  helper_method :current_user, :signed_in?, :current_organization, :current_project, :current_membership

  rescue_from TenantAccess::Forbidden, with: :render_forbidden

  private

  def authenticate_identity!
    return if current_principal

    redirect_to login_page_path, alert: "Please sign in to continue."
  end

  def current_principal
    return @current_principal if defined?(@current_principal)

    @current_principal = RequestIdentity.resolve(
      credentials: session,
      adapter: RequestIdentity::Adapters::Session.new
    )
  rescue RequestIdentity::Unauthorized
    @current_principal = nil
  end

  def current_user
    current_principal&.user
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

  def current_membership
    @current_membership
  end

  def load_organization(id, minimum_role: nil)
    apply_tenant_context(tenant_access.organization(id, minimum_role: minimum_role)).organization
  end

  def load_project(id, minimum_role: nil)
    apply_tenant_context(tenant_access.project(id, minimum_role: minimum_role)).project
  end

  def tenant_access
    @tenant_access ||= TenantAccess.new(user: current_user)
  end

  def apply_tenant_context(context)
    @current_organization = context.organization
    @current_project = context.project
    @current_membership = context.membership
    context
  end

  def render_forbidden
    render plain: "Forbidden", status: :forbidden
  end
end
