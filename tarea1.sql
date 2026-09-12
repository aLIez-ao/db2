SELECT Clientes.nombre, Pedidos.producto, Pedidos.monto
FROM Clientes
INNER JOIN Pedidos ON Clientes.cliente_id = Pedidos.cliente_id;

SELECT Clientes.nombre, Pedidos.producto, Pedidos.monto
FROM Clientes
LEFT JOIN Pedidos ON Clientes.cliente_id = Pedidos.cliente_id;

SELECT * 
FROM Clientes 
WHERE nombre LIKE 'A%' OR ciudad = 'CDMX';

SELECT * 
FROM Pedidos 
WHERE (monto BETWEEN 50 AND 500) AND producto != 'Auriculares';

SELECT Clientes.nombre, Clientes.ciudad, Pedidos.producto, Pedidos.monto
FROM Clientes
INNER JOIN Pedidos ON Clientes.cliente_id = Pedidos.cliente_id
WHERE Clientes.ciudad IN ('Madrid', 'Bogotá');

SELECT Clientes.nombre, Clientes.ciudad
FROM Clientes
LEFT JOIN Pedidos ON Clientes.cliente_id = Pedidos.cliente_id
WHERE Pedidos.pedido_id IS NULL;