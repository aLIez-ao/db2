CREATE DATABASE tienda;

USE tienda;

CREATE TABLE Clientes (
    cliente_id INT PRIMARY KEY,
    nombre VARCHAR(50),
    ciudad VARCHAR(50),
    fecha_registro DATE
);

CREATE TABLE Pedidos (
    pedido_id INT PRIMARY KEY,
    cliente_id INT,
    producto VARCHAR(50),
    monto DECIMAL(10, 2),
    FOREIGN KEY (cliente_id) REFERENCES Clientes(cliente_id)
);

INSERT INTO Clientes (cliente_id, nombre, ciudad, fecha_registro) VALUES
(1, 'Ana Gómez', 'Madrid', '2026-01-15'),
(2, 'Luis Pérez', 'Bogotá', '2026-03-22'),
(3, 'Marta Ruiz', 'CDMX', '2026-05-10'),
(4, 'Carlos Vega', 'Lima', '2026-08-05');

INSERT INTO Pedidos (pedido_id, cliente_id, producto, monto) VALUES
(101, 1, 'Laptop', 1200.00),
(102, 1, 'Ratón Inalámbrico', 25.50),
(103, 2, 'Monitor 24"', 300.00),
(104, 3, 'Teclado Mecánico', 45.00),
(105, 1, 'Auriculares', 80.00);
