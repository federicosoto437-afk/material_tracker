class WebController < ActionController::Base
  layout "web"

  before_action :requerir_sesion

  helper_method :usuario_actual

  private

  def usuario_actual
    @usuario_actual ||= User.find_by(id: session[:user_id])
  end

  def requerir_sesion
    redirect_to login_path, alert: "Inicia sesión para continuar" unless usuario_actual
  end
end