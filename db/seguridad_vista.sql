CREATE ROLE reportes_obra WITH LOGIN PASSWORD 'Reportes123!';

GRANT CONNECT ON DATABASE material_tracker_development TO reportes_obra;
GRANT USAGE ON SCHEMA public TO reportes_obra;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM reportes_obra;
GRANT SELECT ON inventario_materiales TO reportes_obra;