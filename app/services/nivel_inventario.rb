class NivelInventario
  def self.de(material_id, almacen_id: nil, hasta: nil)
    sql = ActiveRecord::Base.sanitize_sql_array(["SELECT nivel_inventario(?, ?, ?)", material_id, almacen_id, hasta])
    ActiveRecord::Base.connection.select_value(sql).to_d
  rescue ActiveRecord::StatementInvalid => error
    raise ActiveRecord::RecordNotFound, "El material #{material_id} no existe" if error.cause.is_a?(PG::NoDataFound)
    raise
  end

  def self.conciliacion(almacen_id: nil)
    sql = ActiveRecord::Base.sanitize_sql_array(["SELECT * FROM niveles_inventario(?)", almacen_id])
    ActiveRecord::Base.connection.select_all(sql).to_a
  end
end