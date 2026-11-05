class MovementsController < ApplicationController
  before_action -> { require_role("admin", "almacenista") }, only: :create

  def index
    movements = Movement.includes(:material, :warehouse, :user).order(created_at: :desc).limit(50)
    render json: movements.map { |movement| movement_json(movement) }
  end

  def create
    resultado = RegistrarMovimiento.call(usuario: current_user, params: movement_params)
    if resultado.exito?
      render json: movement_json(resultado.movimiento), status: :created
    else
      render json: { error: resultado.errores }, status: 422
    end
  end

  private

  def movement_params
    params.expect(movement: [:material_id, :warehouse_id, :movement_type, :quantity, :notes])
  end

  def movement_json(movement)
    {
      id: movement.id,
      type: movement.movement_type,
      material: movement.material.name,
      warehouse: movement.warehouse.name,
      quantity: movement.quantity,
      user: movement.user.name,
      created_at: movement.created_at
    }
  end
end