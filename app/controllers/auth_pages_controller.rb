class AuthPagesController < ApplicationController
  skip_before_action :authenticate_identity!
  before_action :redirect_if_authenticated

  def login; end

  def sign_up; end

  private

  def redirect_if_authenticated
    redirect_to root_path if signed_in?
  end
end
