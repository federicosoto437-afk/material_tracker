class ReporteInventario
  def self.por_almacen(nombre)
    sql = ActiveRecord::Base.sanitize_sql_array([<<~SQL, nombre])
      SELECT sku, material, cantidad, unidad, estado
      FROM inventario_materiales
      WHERE almacen = ?
      ORDER BY sku
    SQL
    ActiveRecord::Base.connection.select_all(sql).to_a
  end

  def self.resumen_por_estado
    ActiveRecord::Base.connection.select_all(<<~SQL).to_a
      SELECT estado, COUNT(DISTINCT material_id) AS materiales, SUM(valor) AS valor_total
      FROM inventario_materiales
      GROUP BY estado
      ORDER BY estado
    SQL
  end

  def self.valor_por_almacen
    ActiveRecord::Base.connection.select_all(<<~SQL).to_a
      SELECT almacen, ubicacion, SUM(valor) AS valor_total
      FROM inventario_materiales
      WHERE almacen IS NOT NULL
      GROUP BY almacen, ubicacion
      ORDER BY valor_total DESC
    SQL
  end
end