require "test_helper"

class NivelInventarioTest < ActiveSupport::TestCase
  setup do
    @cemento = materials(:cemento)
    @central = warehouses(:central)
    @usuario = users(:almacenista)
  end

  test "sin movimientos el nivel es cero" do
    assert_equal 0, NivelInventario.de(@cemento.id)
  end

  test "las entradas suman y las salidas restan" do
    registrar("entrada", 30)
    registrar("salida", 10)
    assert_equal 20, NivelInventario.de(@cemento.id)
  end

  test "un ajuste negativo descuenta la merma" do
    registrar("entrada", 40)
    registrar("ajuste", -5)
    assert_equal 35, NivelInventario.de(@cemento.id)
  end

  test "se puede calcular el nivel de un solo almacen" do
    obra = Warehouse.create!(name: "Obra Torre Norte", location: "Round Rock, TX")
    registrar("entrada", 10)
    registrar("entrada", 15, almacen: obra)
    assert_equal 15, NivelInventario.de(@cemento.id, almacen_id: obra.id)
    assert_equal 25, NivelInventario.de(@cemento.id)
  end

  test "se puede calcular el nivel a una fecha pasada" do
    registrar("entrada", 10).update_column(:created_at, 3.days.ago)
    registrar("entrada", 5)
    assert_equal 10, NivelInventario.de(@cemento.id, hasta: 1.day.ago)
    assert_equal 15, NivelInventario.de(@cemento.id)
  end

  test "el metodo del modelo usa la funcion" do
    registrar("entrada", 12)
    assert_equal 12, @cemento.nivel_calculado
  end

  test "un material inexistente lanza un error" do
    assert_raises(ActiveRecord::RecordNotFound) { NivelInventario.de(999_999) }
  end

  test "la conciliacion detecta stock que no cuadra con los movimientos" do
    registrar("entrada", 30)
    fila = NivelInventario.conciliacion.find { |f| f["sku"] == "CEM-50" }
    assert_equal 30, fila["nivel"]
    assert_equal 80, fila["stock_registrado"]
    assert_equal(-50, fila["diferencia"])
  end

  private

  def registrar(tipo, cantidad, almacen: @central)
    RegistrarMovimiento.call(usuario: @usuario, params: { material_id: @cemento.id, warehouse_id: almacen.id, movement_type: tipo, quantity: cantidad }).movimiento
  end
end