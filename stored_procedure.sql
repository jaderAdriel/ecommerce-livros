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
    INSERT INTO relatorio_vendas_categoria(data_inicio, data_fim, categoria, total_vendido, total_faturado)
    SELECT
	p_data_inicio,
	p_data_fim,
        p_cat.nome,
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


CREATE OR REPLACE PROCEDURE verifica_estoque_item_pedido(p_item_id INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    v_livro_id INTEGER;
    v_qtd_solicitada INTEGER;
    v_qtd_estoque INTEGER;
BEGIN
    -- Busca os dados do item de pedido
    SELECT livro_id, quantidade
    INTO v_livro_id, v_qtd_solicitada
    FROM Itens_Pedido
    WHERE id = p_item_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Item de pedido com ID % não encontrado.', p_item_id;
    END IF;

    -- Busca a quantidade em estoque do livro
    SELECT quantidade_estoque
    INTO v_qtd_estoque
    FROM Livros
    WHERE id = v_livro_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Livro com ID % não encontrado.', v_livro_id;
    END IF;

    -- Verifica se há estoque suficiente
    IF v_qtd_estoque < v_qtd_solicitada THEN
        RAISE EXCEPTION 'Estoque insuficiente para o livro ID %. Solicitado: %, Disponível: %.',
            v_livro_id, v_qtd_solicitada, v_qtd_estoque;
    END IF;
END;
$$;

-- Procedures de gerenciamento de clientes
CREATE OR REPLACE PROCEDURE criar_cliente(
    p_nome VARCHAR,
    p_email VARCHAR,
    p_senha TEXT,
    p_endereco_id INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verifica se o e-mail já existe
    IF EXISTS (SELECT 1 FROM Clientes WHERE email = p_email) THEN
        RAISE EXCEPTION 'Já existe um cliente com o e-mail: %', p_email;
    END IF;

    -- Insere o cliente
    INSERT INTO Clientes (nome, email, senha, endereco_id)
    VALUES (p_nome, p_email, p_senha, p_endereco_id);
END;
$$;


CREATE OR REPLACE PROCEDURE editar_cliente(
    p_id INTEGER,
    p_nome VARCHAR DEFAULT NULL,
    p_email VARCHAR DEFAULT NULL,
    p_senha TEXT DEFAULT NULL,
    p_rua VARCHAR DEFAULT NULL,
    p_numero VARCHAR DEFAULT NULL,
    p_complemento VARCHAR DEFAULT NULL,
    p_bairro VARCHAR DEFAULT NULL,
    p_cidade VARCHAR DEFAULT NULL,
    p_estado VARCHAR DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_endereco_id INTEGER;
BEGIN
    -- Verifica se o cliente existe
    IF NOT EXISTS (SELECT 1 FROM Clientes WHERE id = p_id) THEN
        RAISE EXCEPTION 'Cliente com ID % não encontrado.', p_id;
    END IF;

    -- Atualiza os dados do cliente, se fornecidos
    IF p_nome IS NOT NULL THEN
        UPDATE Clientes SET nome = p_nome WHERE id = p_id;
    END IF;

    IF p_email IS NOT NULL THEN
        UPDATE Clientes SET email = p_email WHERE id = p_id;
    END IF;

    IF p_senha IS NOT NULL THEN
        UPDATE Clientes SET senha = p_senha WHERE id = p_id;
    END IF;

    -- Obtém o endereço vinculado ao cliente
    SELECT endereco_id INTO v_endereco_id FROM Clientes WHERE id = p_id;

    -- Atualiza os campos do endereço, se fornecidos
    IF p_rua IS NOT NULL THEN
        UPDATE Enderecos SET rua = p_rua WHERE id = v_endereco_id;
    END IF;

    IF p_numero IS NOT NULL THEN
        UPDATE Enderecos SET numero = p_numero WHERE id = v_endereco_id;
    END IF;

    IF p_complemento IS NOT NULL THEN
        UPDATE Enderecos SET complemento = p_complemento WHERE id = v_endereco_id;
    END IF;

    IF p_bairro IS NOT NULL THEN
        UPDATE Enderecos SET bairro = p_bairro WHERE id = v_endereco_id;
    END IF;

    IF p_cidade IS NOT NULL THEN
        UPDATE Enderecos SET cidade = p_cidade WHERE id = v_endereco_id;
    END IF;

    IF p_estado IS NOT NULL THEN
        UPDATE Enderecos SET estado = p_estado WHERE id = v_endereco_id;
    END IF;
END;
$$;


CREATE OR REPLACE PROCEDURE excluir_cliente(p_id INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verifica se o cliente existe
    IF NOT EXISTS (SELECT 1 FROM Clientes WHERE id = p_id) THEN
        RAISE EXCEPTION 'Cliente com ID % não encontrado.', p_id;
    END IF;

    -- Opcional: verifique se o cliente tem pedidos antes de excluir

    DELETE FROM Clientes WHERE id = p_id;
END;
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
