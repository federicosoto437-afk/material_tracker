require "test_helper"

class DisparadorInventarioTest < ActiveSupport::TestCase
  setup do
    @cemento = materials(:cemento)
    @central = warehouses(:central)
    @usuario = users(:almacenista)
  end

  test "una entrada aumenta el stock" do
    crear("entrada", 30)
    assert_equal 80, stock
  end

  test "una salida disminuye el stock" do
    crear("salida", 20)
    assert_equal 30, stock
  end

  test "editar la cantidad aplica solo la diferencia" do
    movimiento = crear("entrada", 30)
    movimiento.update!(quantity: 50)
    assert_equal 100, stock
  end

  test "cambiar el almacen mueve el stock de un almacen a otro" do
    obra = Warehouse.create!(name: "Obra Torre Norte", location: "Round Rock, TX")
    movimiento = crear("entrada", 30)
    movimiento.update!(warehouse: obra)
    assert_equal 50, stock
    assert_equal 30, stock(obra)
  end

  test "eliminar un movimiento lo revierte" do
    movimiento = crear("salida", 20)
    movimiento.destroy!
    assert_equal 50, stock
  end

  test "una salida mayor al stock se rechaza y no se guarda" do
    assert_no_difference "Movement.count" do
      assert_raises(ActiveRecord::StatementInvalid) { crear("salida", 999) }
    end
    assert_equal 50, stock
  end

  test "crea el stock si el material no existia en el almacen" do
    nuevo = Warehouse.create!(name: "Almacen Sur", location: "San Antonio, TX")
    crear("entrada", 10, nuevo)
    assert_equal 10, stock(nuevo)
  end

  test "la bitacora registra cada cambio" do
    movimiento = crear("entrada", 30)
    registro = InventarioAuditoria.order(:id).last
    assert_equal "INSERT", registro.operacion
    assert_equal movimiento.id, registro.movement_id
    assert_equal 50, registro.cantidad_anterior
    assert_equal 80, registro.cantidad_nueva
  end

  test "cambiar solo las notas no altera el stock ni la bitacora" do
    movimiento = crear("entrada", 30)
    assert_no_difference "InventarioAuditoria.count" do
      movimiento.update!(notes: "Revisado")
    end
    assert_equal 80, stock
  end

  test "el servicio muestra el mensaje del disparador" do
    resultado = RegistrarMovimiento.call(usuario: @usuario, params: { material_id: @cemento.id, warehouse_id: @central.id, movement_type: "salida", quantity: 999 })
    assert_not resultado.exito?
    assert_match "Stock insuficiente", resultado.errores.first
  end

  private

  def crear(tipo, cantidad, almacen = @central)
    Movement.create!(material: @cemento, warehouse: almacen, user: @usuario, movement_type: tipo, quantity: cantidad)
  end

  def stock(almacen = @central)
    Stock.find_by(material: @cemento, warehouse: almacen).quantity
  end
end