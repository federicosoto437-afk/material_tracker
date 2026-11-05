admin = User.find_or_create_by!(email: "admin@constructify.com") do |user|
  user.name = "Laura Mendez"
  user.password = "Admin123!"
  user.role = "admin"
end

almacenista = User.find_or_create_by!(email: "almacen@constructify.com") do |user|
  user.name = "Carlos Ruiz"
  user.password = "Almacen123!"
  user.role = "almacenista"
end

cemex = Supplier.find_or_create_by!(name: "Cementos del Norte") do |supplier|
  supplier.contact_name = "Ana Torres"
  supplier.phone = "555-123-4567"
  supplier.email = "ventas@cementosnorte.com"
end

aceros = Supplier.find_or_create_by!(name: "Aceros Industriales") do |supplier|
  supplier.contact_name = "Jorge Lopez"
  supplier.phone = "555-987-6543"
  supplier.email = "contacto@acerosind.com"
end

central = Warehouse.find_or_create_by!(name: "Almacen Central") do |warehouse|
  warehouse.location = "Austin, TX"
end

obra = Warehouse.find_or_create_by!(name: "Obra Torre Norte") do |warehouse|
  warehouse.location = "Round Rock, TX"
end

cemento = Material.find_or_create_by!(sku: "CEM-50") do |material|
  material.name = "Cemento gris 50 kg"
  material.unit = "bulto"
  material.unit_cost = 185.50
  material.min_stock = 100
  material.supplier = cemex
end

varilla = Material.find_or_create_by!(sku: "VAR-38") do |material|
  material.name = "Varilla corrugada 3/8"
  material.unit = "pieza"
  material.unit_cost = 142.00
  material.min_stock = 200
  material.supplier = aceros
end

unless Movement.exists?
  Movement.create!(material: cemento, warehouse: central, user: almacenista, movement_type: "entrada", quantity: 500)
  Movement.create!(material: varilla, warehouse: central, user: almacenista, movement_type: "entrada", quantity: 300)
  Movement.create!(material: cemento, warehouse: central, user: almacenista, movement_type: "salida", quantity: 120)
  Movement.create!(material: cemento, warehouse: obra, user: almacenista, movement_type: "entrada", quantity: 120)
  Movement.create!(material: varilla, warehouse: central, user: admin, movement_type: "salida", quantity: 150)
end