require "test_helper"

class ReporteInventarioTest < ActiveSupport::TestCase
  test "el reporte por almacen devuelve sus materiales" do
    resultado = ReporteInventario.por_almacen("Almacen Central")
    assert_equal ["CEM-50"], resultado.map { |fila| fila["sku"] }
  end

  test "el reporte por almacen no permite inyeccion sql" do
    assert_empty ReporteInventario.por_almacen("' OR 1=1 --")
  end

  test "el resumen agrupa los materiales por estado" do
    resumen = ReporteInventario.resumen_por_estado
    assert_equal "Stock bajo", resumen.first["estado"]
    assert_equal 1, resumen.first["materiales"]
  end
end