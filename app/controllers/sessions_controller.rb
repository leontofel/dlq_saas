class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: :create

  def create
    result = Auth::Authenticate.call(**login_params)

    if result.success?
      reset_session
      session[:user_id] = result.user.id
      redirect_to root_path, notice: "Signed in successfully."
    else
      flash.now[:alert] = result.error
      render "auth_pages/login", status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_page_path, notice: "Signed out successfully."
  end

  private

  def login_params
    params.expect(login: %i[email password]).to_h.symbolize_keys
  end
end
