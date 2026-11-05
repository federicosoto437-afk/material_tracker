class ConciliacionController < WebController
  def index
    @filas = NivelInventario.conciliacion
  end
end