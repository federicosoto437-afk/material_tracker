class SessionsController < ApplicationController
  skip_before_action :require_login, only: :create

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)

    if user&.authenticate(params[:password])
      reset_session
      session[:user_id] = user.id
      render json: { id: user.id, name: user.name, role: user.role }, status: :created
    else
      render json: { error: "Credenciales invalidas" }, status: :unauthorized
    end
  end

  def destroy
    reset_session
    head :no_content
  end
end