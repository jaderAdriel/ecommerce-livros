/*
 ____            _       _         _         ____                      _ _        
/ ___|  ___ _ __(_)_ __ | |_    __| | ___   / ___|___  _ __  ___ _   _| | |_ __ _ 
\___ \ / __| '__| | '_ \| __|  / _` |/ _ \ | |   / _ \| '_ \/ __| | | | | __/ _` |
 ___) | (__| |  | | |_) | |_  | (_| |  __/ | |__| (_) | | | \__ \ |_| | | || (_| |
|____/ \___|_|  |_| .__/ \__|  \__,_|\___|  \____\___/|_| |_|___/\__,_|_|\__\__,_|
                  |_|                                                             
*/

-------------------------------------
-- ANÁLISE DE VENDAS E FATURAMENTO --
-------------------------------------

-- Quais são os 10 livros mais vendidos? --

SELECT
    l.titulo,
    a.nome AS autor,
    SUM(ip.quantidade) AS total_vendido
FROM Itens_Pedido ip
JOIN Livros l ON ip.livro_id = l.livro_id
JOIN Pedidos p ON ip.pedido_id = p.pedido_id
JOIN Autores a ON l.autor_id = a.autor_id
WHERE p.status <> 'CANCELADO'
GROUP BY l.livro_id, l.titulo, a.nome
ORDER BY total_vendido DESC
LIMIT 10;


-- Qual o faturamento total por categoria de livro? --

SELECT
    cat.nome AS categoria,
    TO_CHAR(SUM(ip.quantidade * ip.preco_unitario), 'L999G999D99') AS faturamento_total
FROM Itens_Pedido ip
JOIN Livros l ON ip.livro_id = l.livro_id
JOIN Categorias cat ON l.categoria_id = cat.categoria_id
JOIN Pedidos p ON ip.pedido_id = p.pedido_id
WHERE p.status <> 'CANCELADO'
GROUP BY cat.nome
ORDER BY SUM(ip.quantidade * ip.preco_unitario) DESC;


-- Faturamento mensal --

SELECT
    TO_CHAR(p.data_pedido, 'YYYY-MM') AS mes_ano,
    COUNT(DISTINCT p.pedido_id) AS total_pedidos,
    TO_CHAR(SUM(ip.quantidade * ip.preco_unitario), 'L999G999D99') AS faturamento_livros
FROM Pedidos p
JOIN Itens_Pedido ip ON p.pedido_id = ip.pedido_id
WHERE p.status <> 'CANCELADO'
GROUP BY mes_ano
ORDER BY mes_ano;


-- Qual o valor médio por pedido? --

SELECT
    TO_CHAR(AVG(total_pedido), 'L999G999D99') AS ticket_medio
FROM (
    SELECT
        p.pedido_id,
        SUM(ip.quantidade * ip.preco_unitario) + p.frete AS total_pedido
    FROM Pedidos p
    JOIN Itens_Pedido ip ON p.pedido_id = ip.pedido_id
    WHERE p.status <> 'CANCELADO'
    GROUP BY p.pedido_id, p.frete
) AS subquery_pedidos;


-------------------------
-- ANÁLISE DE CLIENTES --
-------------------------

-- Quais são os 10 clientes mais ativos? --

SELECT
    c.nome,
    c.email,
    COUNT(p.pedido_id) AS numero_de_pedidos
FROM Clientes c
JOIN Pedidos p ON c.cliente_id = p.cliente_id
WHERE p.status <> 'CANCELADO'
GROUP BY c.cliente_id, c.nome, c.email
ORDER BY numero_de_pedidos DESC
LIMIT 10;


-- Quais são os 10 clientes que mais gastaram? --

SELECT
    c.nome,
    TO_CHAR(SUM(ip.quantidade * ip.preco_unitario), 'L999G999D99') AS total_gasto_em_livros
FROM Clientes c
JOIN Pedidos p ON c.cliente_id = p.cliente_id
JOIN Itens_Pedido ip ON p.pedido_id = ip.pedido_id
WHERE p.status <> 'CANCELADO'
GROUP BY c.cliente_id, c.nome
ORDER BY SUM(ip.quantidade * ip.preco_unitario) DESC
LIMIT 10;


-- Distribuição de clientes por estado --

SELECT
    e.estado,
    COUNT(c.cliente_id) AS quantidade_de_clientes
FROM Clientes c
JOIN Enderecos e ON c.endereco_id = e.endereco_id
GROUP BY e.estado
ORDER BY quantidade_de_clientes DESC;


-----------------------------------
-- ANÁLISE DE AUTORES E EDITORAS --
-----------------------------------

-- Quais são os 10 autores mais populares? --

SELECT
    a.nome AS autor,
    a.nacionalidade,
    SUM(ip.quantidade) AS total_livros_vendidos
FROM Autores a
JOIN Livros l ON a.autor_id = l.autor_id
JOIN Itens_Pedido ip ON l.livro_id = ip.livro_id
JOIN Pedidos p ON ip.pedido_id = p.pedido_id
WHERE p.status <> 'CANCELADO'
GROUP BY a.autor_id, a.nome, a.nacionalidade
ORDER BY total_livros_vendidos DESC
LIMIT 10;


-- Quais editoras geram mais faturamento? --

SELECT
    ed.nome AS editora,
    ed.pais,
    TO_CHAR(SUM(ip.quantidade * ip.preco_unitario), 'L999G999D99') AS faturamento_gerado
FROM Editoras ed
JOIN Livros l ON ed.editora_id = l.editora_id
JOIN Itens_Pedido ip ON l.livro_id = ip.livro_id
JOIN Pedidos p ON ip.pedido_id = p.pedido_id
WHERE p.status <> 'CANCELADO'
GROUP BY ed.editora_id, ed.nome, ed.pais
ORDER BY SUM(ip.quantidade * ip.preco_unitario) DESC
LIMIT 10;

-------------------------------------
-- ANÁLISE DE INVENTÁRIO E PEDIDOS --
-------------------------------------

-- Quais livros estão com estoque baixo? --

SELECT
    l.titulo,
    a.nome AS autor,
    l.quantidade_estoque
FROM Livros l
JOIN Autores a ON l.autor_id = a.autor_id
WHERE l.quantidade_estoque < 20
ORDER BY l.quantidade_estoque ASC;


-- Quais livros nunca foram vendidos? --

SELECT
    l.titulo,
    a.nome AS autor,
    l.preco,
    l.quantidade_estoque
FROM Livros l
LEFT JOIN Itens_Pedido ip ON l.livro_id = ip.livro_id
JOIN Autores a ON l.autor_id = a.autor_id
WHERE ip.livro_id IS NULL
ORDER BY l.titulo;


-- Resumo do status atual dos pedidos --

SELECT
    status,
    COUNT(pedido_id) AS quantidade
FROM Pedidos
GROUP BY status
ORDER BY status;


-- Quais itens estão nos carrinhos abandonados? --

SELECT
    c.nome AS cliente,
    c.email,
    l.titulo AS livro_no_carrinho,
    cr.quantidade
FROM Carrinho cr
JOIN Clientes c ON cr.cliente_id = c.cliente_id
JOIN Livros l ON cr.livro_id = l.livro_id
ORDER BY c.nome, l.titulo;