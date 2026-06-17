class RegistrationsController < ApplicationController
  skip_before_action :authenticate_user!, only: :create

  def create
    result = Auth::SignUp.call(**sign_up_params)

    if result.success?
      reset_session
      session[:user_id] = result.user.id
      result.user.update_column(:last_sign_in_at, Time.current)
      redirect_to root_path, notice: "Account created."
    else
      flash.now[:alert] = result.error
      render "auth_pages/sign_up", status: :unprocessable_entity
    end
  end

  private

  def sign_up_params
    params.expect(sign_up: %i[email password name]).to_h.symbolize_keys
  end
end
