module Api
  class SystemController < ActionController::API
    def ready
      ActiveRecord::Base.connection.execute("SELECT 1")
      render json: { status: "ok", ready: true }, status: :ok
    rescue StandardError => error
      render json: { status: "error", ready: false, error: error.message }, status: :service_unavailable
    end
  end
end
