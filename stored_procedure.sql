CREATE OR REPLACE PROCEDURE sp_gerar_relatorio_vendas(
    p_data_inicio DATE,
    p_data_fim DATE
)
AS $$
BEGIN
    -- Validação de datas
    IF p_data_inicio IS NULL OR p_data_fim IS NULL THEN
        RAISE EXCEPTION 'Datas devem ser fornecidas';
    END IF;

    IF p_data_inicio IS NULL OR p_data_fim IS NULL THEN
        RAISE EXCEPTION 'As datas de início e fim devem ser fornecidas.';
    END IF;

    IF p_data_inicio > p_data_fim THEN
        RAISE EXCEPTION 'A data de início não pode ser posterior à data de fim.';
    END IF;

    -- Insere dados do relatório
    INSERT INTO relatorio_vendas_categoria(categoria, total_vendido, total_faturado)
    SELECT
        cat.nome,
        SUM(ip.quantidade),
        SUM(ip.quantidade * ip.preco_unitario)
    FROM pedidos p
    JOIN itens_pedido ip ON p.id = ip.pedido_id
    JOIN livros l ON ip.livro_id = l.id
    JOIN categorias cat ON l.categoria_id = cat.id
    WHERE DATE(p.data_pedido) BETWEEN p_data_inicio AND p_data_fim
    GROUP BY cat.nome;
END;
$$ LANGUAGE plpgsql;
