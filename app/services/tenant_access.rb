class TenantAccess
  class Forbidden < StandardError; end

  Context = Data.define(:organization, :project, :membership)

  def initialize(user:)
    @user = user
  end

  def organization(id, minimum_role: nil)
    organization = Organization.visible_to(@user).find(id)

    build_context(organization, nil, minimum_role)
  end

  def project(id, minimum_role: nil)
    project = Project.joins(:organization)
                     .merge(Organization.visible_to(@user))
                     .find(id)

    build_context(project.organization, project, minimum_role)
  end

  private

  def build_context(organization, project, minimum_role)
    membership = @user.organization_memberships.find_by!(organization: organization)
    raise Forbidden if minimum_role && !membership.at_least?(minimum_role)

    Context.new(organization: organization, project: project, membership: membership)
  end
end
