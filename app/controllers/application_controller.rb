class ApplicationController < ActionController::Base
  skip_forgery_protection

  before_action :require_login

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable
  rescue_from ActiveRecord::RecordNotDestroyed, with: :conflict
  rescue_from ActiveRecord::InvalidForeignKey, with: :conflict
  rescue_from ActionController::ParameterMissing, with: :bad_request
  rescue_from ActiveRecord::ConnectionNotEstablished, with: :service_unavailable

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def require_login
    render json: { error: "No autenticado" }, status: :unauthorized unless current_user
  end

  def require_role(*roles)
    render json: { error: "Sin permisos" }, status: :forbidden unless roles.include?(current_user.role)
  end

  def not_found
    render json: { error: "Registro no encontrado" }, status: :not_found
  end

  def unprocessable(exception)
    render json: { error: exception.record.errors.full_messages }, status: 422
  end

  def conflict(exception)
    message = exception.respond_to?(:record) ? exception.record.errors.full_messages : "El registro tiene datos relacionados"
    render json: { error: message }, status: :conflict
  end

  def bad_request(exception)
    render json: { error: exception.message }, status: :bad_request
  end

  def service_unavailable
    render json: { error: "Base de datos no disponible" }, status: :service_unavailable
  end
end