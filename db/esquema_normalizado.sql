CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_digest VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'almacenista' CHECK (role IN ('admin', 'almacenista', 'supervisor')),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE suppliers (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL UNIQUE,
    contact_name VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(150),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE categories (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE units (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE,
    name VARCHAR(50) NOT NULL
);

CREATE TABLE projects (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    client_name VARCHAR(150) NOT NULL,
    address VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'planeacion' CHECK (status IN ('planeacion', 'activa', 'terminada')),
    start_date DATE NOT NULL,
    end_date DATE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE TABLE warehouses (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    location VARCHAR(255),
    project_id BIGINT REFERENCES projects(id),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE materials (
    id BIGSERIAL PRIMARY KEY,
    sku VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    category_id BIGINT NOT NULL REFERENCES categories(id),
    unit_id BIGINT NOT NULL REFERENCES units(id),
    supplier_id BIGINT NOT NULL REFERENCES suppliers(id),
    unit_cost NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (unit_cost >= 0),
    min_stock NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (min_stock >= 0),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE stocks (
    id BIGSERIAL PRIMARY KEY,
    material_id BIGINT NOT NULL REFERENCES materials(id),
    warehouse_id BIGINT NOT NULL REFERENCES warehouses(id),
    quantity NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (material_id, warehouse_id)
);

CREATE TABLE movements (
    id BIGSERIAL PRIMARY KEY,
    material_id BIGINT NOT NULL REFERENCES materials(id),
    warehouse_id BIGINT NOT NULL REFERENCES warehouses(id),
    user_id BIGINT NOT NULL REFERENCES users(id),
    movement_type VARCHAR(10) NOT NULL CHECK (movement_type IN ('entrada', 'salida', 'ajuste')),
    quantity NUMERIC(12,2) NOT NULL CHECK (quantity > 0 OR (movement_type = 'ajuste' AND quantity <> 0)),
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_materials_category ON materials(category_id);
CREATE INDEX idx_materials_supplier ON materials(supplier_id);
CREATE INDEX idx_warehouses_project ON warehouses(project_id);
CREATE INDEX idx_movements_material_fecha ON movements(material_id, created_at);