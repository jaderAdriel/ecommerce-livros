--  Exibe os livros mais vendidos em um determinado período.

CREATE OR REPLACE VIEW vw_livros_mais_vendidos AS
SELECT item.livro_id as livro_id
    , SUM(item.quantidade) as total_vendido
    , Livros.titulo as livro_titulo
    , Autores.nome as autor_nome, Autores.id as autor_id
FROM itens_pedido item
JOIN Livros on item.livro_id = Livros.id
JOIN Autores on Livros.autor_id = Autores.id
JOIN Pedidos on item.pedido_id = Pedidos.id

WHERE Pedidos.status != 'CANCELADO'
    AND Pedidos.data_pedido > '2025-01-01 00:00:00'
    AND Pedidos.data_pedido < '2026-01-01 00:00:00'

GROUP BY item.livro_id, Livros.titulo, Autores.nome, Autores.id
ORDER BY total_vendido DESC
LIMIT 10;

EXPLAIN ANALYSE SELECT livro_id, total_vendido, livro_titulo, autor_nome, autor_id from vw_livros_mais_vendidos;



--  ○ vw_clientes_ativos: Exibe os clientes que realizaram compras nos últimos 6 meses.
CREATE OR REPLACE VIEW vw_clientes_ativos AS
SELECT cl.id, cl.nome
FROM Clientes cl
JOIN Pedidos p on cl.id = p.cliente_id
WHERE p.data_pedido >=  CURRENT_DATE - INTERVAL '6 months'
GROUP BY cl.id;


SELECT * FROM vw_clientes_ativos;


--  ○ vw_estoque_baixo: Exibe os livros com quantidade em estoque abaixo de um determinado limite.
