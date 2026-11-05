class MaterialsController < ApplicationController
  before_action :set_material, only: [:show, :update, :destroy]
  before_action -> { require_role("admin") }, only: [:create, :update, :destroy]

  def index
    render json: Material.includes(:supplier).order(:sku).map { |material| material_json(material) }
  end

  def show
    render json: material_json(@material)
  end

  def create
    material = Material.create!(material_params)
    render json: material_json(material), status: :created
  end

  def update
    @material.update!(material_params)
    render json: material_json(@material)
  end

  def destroy
    @material.destroy!
    head :no_content
  end

  private

  def set_material
    @material = Material.find(params[:id])
  end

  def material_params
    params.expect(material: [:sku, :name, :unit, :unit_cost, :min_stock, :supplier_id])
  end

  def material_json(material)
    material.as_json(only: [:id, :sku, :name, :unit, :unit_cost, :min_stock]).merge(
      supplier: material.supplier.name,
      total_stock: material.total_stock
    )
  end
end