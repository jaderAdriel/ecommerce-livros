CREATE OR REPLACE PROCEDURE sp_gerar_relatorio_vendas(
    p_data_inicio DATE,
    p_data_fim DATE
)
AS $$
BEGIN
    -- Validação de datas
    IF p_data_inicio IS NULL OR p_data_fim IS NULL THEN
        RAISE EXCEPTION 'As datas de início e fim devem ser fornecidas.';
    END IF;

    IF p_data_inicio > p_data_fim THEN
        RAISE EXCEPTION 'A data de início não pode ser posterior à data de fim.';
    END IF;
    
    -- Limpando a tabela em caso de duplicata para idempotência
    
    DELETE FROM relatorio_vendas_categoria
    WHERE data_inicio = p_data_inicio 
    AND data_fim = p_data_fim;

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
    WHERE p.status <> 'CANCELADO' AND p.data_pedido >= p_data_inicio
    AND p.data_pedido < (p_data_fim + INTERVAL '1 day') 
    GROUP BY cat.nome;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE PROCEDURE sp_inserir_cliente(
    p_nome VARCHAR(100),
    p_email VARCHAR(40),
    p_senha TEXT,
    p_endereco_estado VARCHAR(59),
    p_endereco_cidade VARCHAR(168),
    p_endereco_bairro VARCHAR(58),
    p_endereco_rua VARCHAR(100),
    p_endereco_complemento VARCHAR(255),
    p_endereco_numero VARCHAR(10)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_endereco_id INTEGER;
BEGIN
    -- Validação básica dos dados
    IF p_nome IS NULL OR p_email IS NULL OR p_senha IS NULL OR p_endereco_estado IS NULL
           OR p_endereco_cidade IS NULL OR p_endereco_rua IS NULL OR p_endereco_numero  IS NULL THEN
        RAISE EXCEPTION 'Todos os campos obrigatórios devem ser fornecidos (nome, email, senha, estado, cidade, rua, numero)';
    END IF;

    -- Normaliza os dados
    p_endereco_estado := LOWER(p_endereco_estado);
    p_endereco_cidade := LOWER(p_endereco_cidade);
    p_endereco_bairro := LOWER(p_endereco_bairro);
    p_endereco_rua := LOWER(p_endereco_rua);
    p_endereco_complemento := LOWER(p_endereco_complemento);
    p_endereco_numero := LOWER(p_endereco_numero);

    IF LENGTH(p_senha) < 8 THEN
        RAISE EXCEPTION 'Senha deve ter no minimo 8 caracteres';
    end if;

    INSERT INTO Enderecos(rua, numero, complemento, bairro, cidade, estado)
    VALUES (p_endereco_rua, p_endereco_numero, p_endereco_complemento, p_endereco_bairro, p_endereco_cidade, p_endereco_estado)
    RETURNING id INTO v_endereco_id;

    BEGIN
        INSERT INTO Clientes(nome, email, senha, endereco_id) VALUES (p_nome, p_email, p_senha, endereco_id);
        RAISE NOTICE 'CLIENTE CADASTRADO COM SUCESSO';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE EXCEPTION 'O e-mail ''%'' já está em uso', p_email
            USING ERRCODE = 'P0002';
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Erro ao inserir livro: %', SQLERRM;
    END;

END
$$;



CREATE OR REPLACE PROCEDURE sp_inserir_livro(
    IN p_titulo VARCHAR(124),
    IN p_isbn VARCHAR(17),
    IN p_preco DECIMAL(10, 2),
    IN p_quantidade_estoque INTEGER,
    IN p_autor_id INTEGER,
    IN p_editora_id INTEGER,
    IN p_categoria_id INTEGER,
    OUT p_livro_id INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validação básica dos dados
    IF p_titulo IS NULL OR p_isbn IS NULL OR p_preco IS NULL OR p_quantidade_estoque IS NULL
           OR p_autor_id IS NULL OR p_categoria_id IS NULL OR p_editora_id IS NULL THEN
        RAISE EXCEPTION 'Todos os campos obrigatórios devem ser fornecidos';
    END IF;

    BEGIN
        INSERT INTO Livros(titulo, autor_id, isbn, editora_id, preco, quantidade_estoque, categoria_id)
        VALUES (p_titulo, autor_id, p_isbn, editora_id, p_preco, p_quantidade_estoque, categoria_id)
        RETURNING id INTO p_livro_id;


        RAISE NOTICE 'LIVRO INSERIDO COM SUCESSO. ID: %', p_livro_id;
    EXCEPTION
        WHEN unique_violation THEN
            RAISE EXCEPTION 'Já existe um livro com o ISBN "%"', p_isbn
            USING ERRCODE = 'P0002';
        WHEN foreign_key_violation THEN
            RAISE EXCEPTION 'Violação de chave estrangeira : %', SQLERRM
            USING ERRCODE = '23503'; -- 23503 -> Violação de chave ESTRANGEIRA
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Erro ao inserir livro: %', SQLERRM;
    END;
END;
$$;



CREATE OR REPLACE PROCEDURE sp_inserir_livro_por_nomes(
    IN p_titulo VARCHAR(124),
    IN p_isbn VARCHAR(17),
    IN p_preco DECIMAL(10, 2),
    IN p_quantidade_estoque INTEGER,
    IN p_autor_id INTEGER,
    IN p_editora_nome VARCHAR(100),
    IN p_editora_pais VARCHAR(50),
    IN p_categoria_nome VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_editora_id INTEGER;
    v_categoria_id INTEGER;
BEGIN
    -- Normaliza os dados
    p_editora_nome   := LOWER(p_editora_nome);
    p_editora_pais   := LOWER(p_editora_pais);
    p_categoria_nome := LOWER(p_categoria_nome);

    -- Validação básica dos dados
    IF p_titulo IS NULL OR p_isbn IS NULL OR p_preco IS NULL OR p_quantidade_estoque IS NULL
           OR p_autor_id IS NULL OR p_categoria_nome IS NULL THEN
        RAISE EXCEPTION 'Todos os campos obrigatórios devem ser fornecidos';
    END IF;

    IF p_preco <= 0 THEN
        RAISE EXCEPTION 'Valor de preço informado é inválido %', p_preco;
    end if;

    IF p_quantidade_estoque < 0 THEN
        RAISE EXCEPTION 'A quantidade em estoque não pode ser negativa';
    END IF;

--     Busca o ID da editora pelo nome e o pais
    SELECT id INTO v_editora_id FROM Editoras WHERE LOWER(pais) = p_editora_pais AND LOWER(nome) = p_editora_nome;

--     Verifica se existe editora com os atributos informados, se não existir, salva a editora e salva seu id
    IF v_editora_id IS NULL THEN
        INSERT INTO Editoras (pais, nome) VALUES (p_editora_pais, p_editora_nome) RETURNING id INTO v_editora_id;
    end if;

--     Busca o ID da categoria pelo nome
    SELECT id INTO v_categoria_id FROM  Categorias WHERE LOWER(nome) = p_categoria_nome;

--     Verifica se existe categoria com o nome informado, se não existir, salva a categoria e salva seu id
    IF v_categoria_id IS NULL THEN
        INSERT INTO Categorias (nome) VALUES ( p_categoria_nome) RETURNING id INTO v_categoria_id;
    end if;

    BEGIN
        INSERT INTO Livros(titulo, autor_id, isbn, editora_id, preco, quantidade_estoque, categoria_id)
        VALUES (p_titulo, p_autor_id, p_isbn, editora_id, p_preco, p_quantidade_estoque, categoria_id);

        RAISE NOTICE 'LIVRO INSERIDO COM SUCESSO';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE EXCEPTION 'Já existe um livro com o ISBN "%"', p_isbn
            USING ERRCODE = 'P0002'; -- P0002 -> Violação de contraint
        WHEN foreign_key_violation THEN
            RAISE EXCEPTION 'Autor com id "%" não existe', p_autor_id
            USING ERRCODE = '23503'; -- 23503 -> Violação de chave ESTRANGEIRA
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Erro ao inserir livro: %', SQLERRM;
    END;
END;
$$;



CREATE TYPE Item_Info AS (
    livro_id INTEGER,
    quantidade INTEGER
);


CREATE OR REPLACE PROCEDURE sp_fazer_pedido(
    IN p_cliente_id INTEGER,
    IN p_itens Item_Info[],
    IN p_data_pedido TIMESTAMP
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_pedido_id INTEGER;
BEGIN

    IF p_cliente_id IS NULL THEN
        RAISE EXCEPTION 'ID de cliente não pode ser nulo';
    end if;

    IF p_itens IS NULL OR array_length(p_itens, 1) < 1 THEN
        RAISE EXCEPTION 'Precisa ser informado ao menos um item para prosseguir com pedido';
    end if;

    IF p_data_pedido IS NULL THEN
        p_data_pedido := CURRENT_TIMESTAMP;
    end if;


    INSERT INTO Pedidos(cliente_id, data_pedido)
    VALUES (p_cliente_id, p_data_pedido)
    RETURNING id INTO v_pedido_id;

    CALL sp_inserir_item_pedido(v_pedido_id, p_itens);
    RAISE NOTICE 'PEDIDO FEITO COM SUCESSO. ID % ', v_pedido_id;
END;
$$;



CREATE OR REPLACE PROCEDURE sp_inserir_item_pedido (
    IN p_pedido_id INTEGER,
    IN p_itens Item_Info[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_item Item_Info;
    v_preco DECIMAL(10, 2);
    v_quantidade_estoque INTEGER;
BEGIN
    FOREACH v_item IN ARRAY p_itens LOOP
        SELECT preco, quantidade_estoque
        INTO v_preco, v_quantidade_estoque
        FROM livros
        WHERE id = v_item.livro_id;

        -- A variavél found é falsa quando o SELECT INTO não retornou algo
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Livro com ID % não encontrado', v_item.livro_id;
        END IF;

        IF v_item.quantidade IS NULL OR v_item.quantidade < 1 THEN
            RAISE EXCEPTION 'Quantidade inválida para livro ID %: %', v_item.livro_id, v_item.quantidade;
        end if;

        IF v_quantidade_estoque < v_item.quantidade THEN
            RAISE EXCEPTION 'O livro com ID % não possui estoque suficiente. Quantidade desejada ''%'', Quantidade em estoque ''%'' ',
                v_item.livro_id, v_item.quantidade, v_quantidade_estoque;
        end if;

        -- Adiciona o item ao pedido
        INSERT INTO Itens_Pedido(pedido_id, livro_id, quantidade, preco_unitario)
        VALUES (p_pedido_id, v_item.livro_id, v_item.quantidade, v_preco);

        -- Atualiza o estoque
        BEGIN
            UPDATE Livros
            SET quantidade_estoque = quantidade_estoque - v_item.quantidade
            WHERE id = v_item.livro_id;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE EXCEPTION 'Erro ao atualizar estoque do livro ID %: %', v_item.livro_id, SQLERRM;
        END;

    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao inserir itens ao pedido: %', SQLERRM;
end;
$$;

-- EXEMPLO:
-- CALL sp_fazer_pedido(
--     2, -- > id do cliente
--     ARRAY[ --> Array com linhas genericas, que representa itens do pedido (livro_id, quantidade)
--         ROW(6, 1)::Item_Info,
--         ROW(5, 3)::Item_Info
--     ],
--     '2025-07-05 14:30:00'
-- );