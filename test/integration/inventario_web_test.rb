require "test_helper"

class InventarioWebTest < ActionDispatch::IntegrationTest
  test "sin sesion redirige al login" do
    get inventario_path
    assert_redirected_to login_path
  end

  test "un login incorrecto muestra un error" do
    post login_path, params: { email: "almacen@constructify.com", password: "clave_mala" }
    assert_response 422
    assert_match "Correo o contraseña incorrectos", response.body
  end

  test "el almacenista ve el inventario con el stock bajo marcado" do
    iniciar_sesion("almacen@constructify.com", "Almacen123!")
    follow_redirect!
    assert_response :success
    assert_select "tr.bajo td", "CEM-50"
  end

  test "el almacenista registra una salida desde el formulario" do
    iniciar_sesion("almacen@constructify.com", "Almacen123!")
    post movimientos_path, params: { movement: { material_id: materials(:cemento).id, warehouse_id: warehouses(:central).id, movement_type: "salida", quantity: 10 } }
    assert_redirected_to inventario_path
    assert_equal 40, materials(:cemento).total_stock
  end

  test "el supervisor no puede registrar movimientos" do
    iniciar_sesion("supervisor@constructify.com", "Super123!")
    post movimientos_path, params: { movement: { material_id: materials(:cemento).id, warehouse_id: warehouses(:central).id, movement_type: "entrada", quantity: 10 } }
    assert_response 422
    assert_match "No tienes permiso", response.body
  end

  private

  def iniciar_sesion(email, clave)
    post login_path, params: { email: email, password: clave }
  end
end