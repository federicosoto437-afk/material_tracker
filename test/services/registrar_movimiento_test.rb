require "test_helper"

class RegistrarMovimientoTest < ActiveSupport::TestCase
  setup do
    @cemento = materials(:cemento)
    @central = warehouses(:central)
  end

  test "una entrada aumenta el stock" do
    resultado = RegistrarMovimiento.call(usuario: users(:almacenista), params: datos("entrada", 30))
    assert resultado.exito?
    assert_equal 80, @cemento.total_stock
  end

  test "una salida disminuye el stock" do
    resultado = RegistrarMovimiento.call(usuario: users(:almacenista), params: datos("salida", 20))
    assert resultado.exito?
    assert_equal 30, @cemento.total_stock
  end

  test "una salida mayor al stock se rechaza y no cambia nada" do
    assert_no_difference "Movement.count" do
      resultado = RegistrarMovimiento.call(usuario: users(:almacenista), params: datos("salida", 99999))
      assert_not resultado.exito?
    end
    assert_equal 50, @cemento.total_stock
  end

  test "un supervisor no puede registrar movimientos" do
    resultado = RegistrarMovimiento.call(usuario: users(:supervisor), params: datos("entrada", 10))
    assert_not resultado.exito?
    assert_includes resultado.errores, "No tienes permiso para registrar movimientos"
  end

  test "un material debajo de su minimo tiene stock bajo" do
    assert @cemento.stock_bajo?
  end

  private

  def datos(tipo, cantidad)
    { material_id: @cemento.id, warehouse_id: @central.id, movement_type: tipo, quantity: cantidad }
  end
end