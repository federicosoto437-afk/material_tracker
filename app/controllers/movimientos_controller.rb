class MovimientosController < WebController
  def new
    @movimiento = Movement.new
    cargar_opciones
  end

  def create
    resultado = RegistrarMovimiento.call(usuario: usuario_actual, params: movimiento_params)

    if resultado.exito?
      redirect_to inventario_path, notice: "Movimiento registrado"
    else
      @movimiento = Movement.new(movimiento_params)
      @errores = resultado.errores
      cargar_opciones
      render :new, status: 422
    end
  end

  private

  def movimiento_params
    params.expect(movement: [:material_id, :warehouse_id, :movement_type, :quantity, :notes])
  end

  def cargar_opciones
    @materiales = Material.order(:name)
    @almacenes = Warehouse.order(:name)
  end
end