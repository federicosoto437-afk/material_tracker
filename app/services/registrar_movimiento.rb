class RegistrarMovimiento
  ROLES_PERMITIDOS = %w[admin almacenista].freeze

  Resultado = Data.define(:exito, :movimiento, :errores) do
    def exito?
      exito
    end
  end

  def self.call(usuario:, params:)
    new(usuario, params).call
  end

  def initialize(usuario, params)
    @usuario = usuario
    @params = params
  end

  def call
    return fallo("No tienes permiso para registrar movimientos") unless ROLES_PERMITIDOS.include?(@usuario&.role)

    movimiento = Movement.new(@params.merge(user: @usuario))
    movimiento.save!
    Resultado.new(exito: true, movimiento: movimiento, errores: [])
  rescue ActiveRecord::RecordInvalid => error
    fallo(*error.record.errors.full_messages)
  end

  private

  def fallo(*mensajes)
    Resultado.new(exito: false, movimiento: nil, errores: mensajes)
  end
end