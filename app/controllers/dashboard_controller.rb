class DashboardController < ApplicationController
  def show
    @organizations = Organization.visible_to(current_user).includes(:projects)
    @recent_projects = Project.joins(:organization)
                              .merge(Organization.visible_to(current_user))
                              .order(updated_at: :desc)
                              .limit(5)
  end
end
