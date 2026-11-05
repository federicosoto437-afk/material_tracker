require "test_helper"

class InventarioMaterialTest < ActiveSupport::TestCase
  test "la vista combina material, proveedor y almacen" do
    fila = InventarioMaterial.find_by(sku: "CEM-50")
    assert_equal "Cementos del Norte", fila.proveedor
    assert_equal "Almacen Central", fila.almacen
    assert_equal 50, fila.cantidad
  end

  test "un material debajo de su minimo aparece en stock bajo" do
    assert_equal "Stock bajo", InventarioMaterial.find_by(sku: "CEM-50").estado
  end

  test "un material con suficiente stock aparece disponible" do
    stocks(:cemento_central).update!(quantity: 150)
    assert_equal "Disponible", InventarioMaterial.find_by(sku: "CEM-50").estado
  end

  test "un material sin existencias aparece como sin stock" do
    Material.create!(sku: "ARE-01", name: "Arena de rio", unit: "m3", unit_cost: 350, min_stock: 10, supplier: suppliers(:cementos))
    fila = InventarioMaterial.find_by(sku: "ARE-01")
    assert_equal "Sin stock", fila.estado
    assert_nil fila.almacen
  end

  test "el stock total suma todos los almacenes" do
    obra = Warehouse.create!(name: "Obra Torre Norte", location: "Round Rock, TX")
    Stock.create!(material: materials(:cemento), warehouse: obra, quantity: 70)
    filas = InventarioMaterial.where(sku: "CEM-50").to_a
    assert_equal 2, filas.size
    assert filas.all? { |fila| fila.stock_total == 120 }
    assert filas.all? { |fila| fila.estado == "Disponible" }
  end

  test "el valor es la cantidad por el costo unitario" do
    assert_equal 9275, InventarioMaterial.find_by(sku: "CEM-50").valor
  end

  test "la vista refleja un movimiento registrado" do
    RegistrarMovimiento.call(usuario: users(:almacenista), params: { material_id: materials(:cemento).id, warehouse_id: warehouses(:central).id, movement_type: "entrada", quantity: 25 })
    assert_equal 75, InventarioMaterial.find_by(sku: "CEM-50").cantidad
  end

  test "la vista es de solo lectura" do
    assert_raises(ActiveRecord::ReadOnlyRecord) do
      InventarioMaterial.find_by(sku: "CEM-50").update(cantidad: 0)
    end
  end
end