class InventarioController < WebController
  def index
    @materiales = Material.includes(:supplier).order(:sku)
    @movimientos = Movement.includes(:material, :warehouse, :user).order(created_at: :desc).limit(10)
  end
end