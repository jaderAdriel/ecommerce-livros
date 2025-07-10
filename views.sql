--  Exibe os livros mais vendidos em um determinado período. calculado a cada execução
CREATE OR REPLACE VIEW vw_livros_mais_vendidos AS
SELECT ip.livro_id as livro_id
    , SUM(ip.quantidade) as total_vendido
FROM itens_pedido ip
JOIN Pedidos p on ip.pedido_id = p.id
WHERE p.status != 'CANCELADO'
    AND p.data_pedido BETWEEN CURRENT_TIMESTAMP - INTERVAL '1 year' AND CURRENT_TIMESTAMP
GROUP BY ip.livro_id
ORDER BY total_vendido DESC
LIMIT 10;

SELECT livro_id, total_vendido, l.titulo
from vw_livros_mais_vendidos
join Livros l on l.id = livro_id
;

--  ○ vw_clientes_ativos: Exibe os clientes que realizaram compras nos últimos 6 meses.
CREATE OR REPLACE VIEW vw_clientes_ativos AS
SELECT cl.id, cl.nome
FROM Clientes cl
JOIN Pedidos p on cl.id = p.cliente_id
WHERE p.data_pedido >=  CURRENT_DATE - INTERVAL '6 months'
GROUP BY cl.id;

-- EXPLAIN ANALYSE SELECT * from vw_clientes_ativos;



--  ○ vw_estoque_baixo: Exibe os livros com quantidade em estoque abaixo de um determinado limite.
CREATE OR REPLACE VIEW vw_estoque_baixo AS
  SELECT * FROM livros WHERE quantidade_estoque <= 4;

-- EXPLAIN ANALYSE SELECT * from vw_estoque_baixo;
