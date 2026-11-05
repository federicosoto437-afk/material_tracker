class SesionesController < WebController
  skip_before_action :requerir_sesion, only: [:new, :create]

  def new
  end

  def create
    usuario = User.find_by(email: params[:email].to_s.strip.downcase)

    if usuario&.authenticate(params[:password])
      reset_session
      session[:user_id] = usuario.id
      redirect_to inventario_path, notice: "Bienvenido, #{usuario.name}"
    else
      flash.now[:alert] = "Correo o contraseña incorrectos"
      render :new, status: 422
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Sesión cerrada"
  end
end