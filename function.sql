/*
Regras de descontos:
    1. Total do pedido:
        Acima de R$ 65 → 10% de desconto
        Acima de R$ 30 → 5% de desconto

    2. Quantidade total de livros no pedido:
        Mais de 10 livros → 7% de desconto

    3. Cliente com mais de 5 pedidos anteriores ENTREGUES:
        Cliente fiel → 5% de desconto

    --  Combinação de descontos:
        acumulativo de no máximo 40% de desconto
 */

CREATE OR REPLACE FUNCTION fn_calcular_desconto(p_pedido_id INTEGER)
RETURNS NUMERIC(10, 2) AS $$
DECLARE
    v_total NUMERIC(10, 2);
    v_total_livros INTEGER;
    v_pedidos_entregues INTEGER;
    v_desconto NUMERIC(5,2) := 0;
BEGIN
    -- Total do pedido (soma dos itens)
    SELECT SUM(quantidade * preco_unitario) INTO v_total FROM itens_pedido WHERE pedido_id = p_pedido_id;

    -- Total de livros no pedido
    SELECT SUM(quantidade) INTO v_total_livros FROM itens_pedido WHERE pedido_id = p_pedido_id;

    -- Pedidos entregues do cliente
    SELECT COUNT(*) INTO v_pedidos_entregues FROM pedidos WHERE cliente_id =
    (SELECT cliente_id FROM pedidos WHERE id = p_pedido_id) AND status = 'ENTREGUE';

    -- Aplicar regras de desconto
    IF v_total >= 65 THEN
        v_desconto := v_desconto + 0.10;
    ELSIF v_total >= 30 THEN
        v_desconto := v_desconto + 0.05;
    END IF;

    IF v_total_livros > 10 THEN
        v_desconto := v_desconto + 0.07;
    END IF;

    IF v_pedidos_entregues > 5 THEN
        v_desconto := v_desconto + 0.05;
    END IF;

    -- Verificar valor máximo de desconto possível
    IF v_desconto > 0.4 THEN
        v_desconto := 0.4;
    END IF;

    -- Retornar valor do desconto aplicado em R$
    RETURN ROUND(v_total * v_desconto, 2);
END;
$$ LANGUAGE plpgsql


-- Função de atualizar quantidade em estoque após uma venda
CREATE OR REPLACE FUNCTION atualiza_estoque_pedido()
RETURNS TRIGGER AS $$
DECLARE
    item RECORD;
BEGIN
    -- Verifica se houve mudança no status
    IF NEW.status = 'ENVIADO' AND OLD.status <> 'ENVIADO' THEN
        -- Diminui o estoque
        FOR item IN
            SELECT livro_id, quantidade FROM Itens_Pedido WHERE pedido_id = NEW.id
        LOOP
            UPDATE Livros
            SET quantidade_estoque = quantidade_estoque - item.quantidade
            WHERE id = item.livro_id;
        END LOOP;
        
    ELSIF NEW.status = 'CANCELADO' AND OLD.status = 'ENVIADO' THEN
        -- Restaura o estoque
        FOR item IN
            SELECT livro_id, quantidade FROM Itens_Pedido WHERE pedido_id = NEW.id
        LOOP
            UPDATE Livros
            SET quantidade_estoque = quantidade_estoque + item.quantidade
            WHERE id = item.livro_id;
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

