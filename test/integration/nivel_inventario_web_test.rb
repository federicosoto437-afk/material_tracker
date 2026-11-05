require "test_helper"

class NivelInventarioWebTest < ActionDispatch::IntegrationTest
  test "la api devuelve el nivel calculado de un material" do
    post session_path, params: { email: "almacen@constructify.com", password: "Almacen123!" }, as: :json
    get nivel_material_path(materials(:cemento)), as: :json
    assert_response :success
    assert_equal "CEM-50", response.parsed_body["sku"]
    assert_equal "0.0", response.parsed_body["nivel"]
  end

  test "la api responde 404 si el material no existe" do
    post session_path, params: { email: "almacen@constructify.com", password: "Almacen123!" }, as: :json
    get nivel_material_path(id: 999_999), as: :json
    assert_response :not_found
  end

  test "la pagina de conciliacion muestra los niveles" do
    post login_path, params: { email: "almacen@constructify.com", password: "Almacen123!" }
    RegistrarMovimiento.call(usuario: users(:almacenista), params: { material_id: materials(:cemento).id, warehouse_id: warehouses(:central).id, movement_type: "entrada", quantity: 30 })
    get conciliacion_path
    assert_response :success
    assert_select "td", "CEM-50"
  end
end