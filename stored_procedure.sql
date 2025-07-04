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
    
    -- Limpando a tabela para idempotência
    
    TRUNCATE TABLE relatorio_vendas_categoria;

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
    c_nome VARCHAR(100),
    c_email VARCHAR(40),
    c_senha TEXT,
    c_endereco_estado VARCHAR(59),
    c_endereco_cidade VARCHAR(168),
    c_endereco_bairro VARCHAR(58),
    c_endereco_rua VARCHAR(100),
    c_endereco_complemento VARCHAR(255),
    c_endereco_numero VARCHAR(10)
)
LANGUAGE plpgsql
AS $$
DECLARE
    endereco_id INTEGER;
BEGIN
    -- Validação básica dos dados
    IF c_nome IS NULL OR c_email IS NULL OR c_senha IS NULL OR c_endereco_estado IS NULL
           OR c_endereco_cidade IS NULL OR c_endereco_rua IS NULL OR c_endereco_numero  IS NULL THEN
        RAISE EXCEPTION 'Todos os campos obrigatórios devem ser fornecidos (nome, email, senha, estado, cidade, rua, numero)';
    END IF;

    c_endereco_estado := LOWER(c_endereco_estado);
    c_endereco_cidade := LOWER(c_endereco_cidade);
    c_endereco_bairro := LOWER(c_endereco_bairro);
    c_endereco_rua := LOWER(c_endereco_rua);
    c_endereco_complemento := LOWER(c_endereco_complemento);
    c_endereco_numero := LOWER(c_endereco_numero);

    IF LENGTH(c_senha) < 8 THEN
        RAISE EXCEPTION 'Senha deve ter no minimo 8 caracteres';
    end if;

    INSERT INTO Enderecos(rua, numero, complemento, bairro, cidade, estado)
    VALUES (c_endereco_rua, c_endereco_numero, c_endereco_complemento, c_endereco_bairro, c_endereco_cidade, c_endereco_estado)
    RETURNING id INTO endereco_id;

    BEGIN
        INSERT INTO Clientes(nome, email, senha, endereco_id) VALUES (c_nome, c_email, c_senha, endereco_id);
        RAISE NOTICE 'CLIENTE CADASTRADO COM SUCESSO';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE EXCEPTION 'O e-mail ''%'' já está em uso', c_email
            USING ERRCODE = 'P0002';
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Erro ao inserir livro: %', SQLERRM;
    END;

END
$$;


CREATE OR REPLACE PROCEDURE sp_inserir_livro_por_nomes(
    IN l_titulo VARCHAR(124),
    IN l_isbn VARCHAR(17),
    IN l_preco DECIMAL(10, 2),
    IN l_quantidade_estoque INTEGER,
    IN l_autor_id INTEGER,
    IN editora_nome VARCHAR(100),
    IN editora_pais VARCHAR(50),
    IN categoria_nome VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
DECLARE
    editora_id INTEGER;
    categoria_id INTEGER;
BEGIN

    editora_nome   := LOWER(editora_nome);
    editora_pais   := LOWER(editora_pais);
    categoria_nome := LOWER(categoria_nome);

    -- Validação básica dos dados
    IF l_titulo IS NULL OR l_isbn IS NULL OR l_preco IS NULL OR l_quantidade_estoque IS NULL
           OR l_autor_id IS NULL OR categoria_nome IS NULL THEN
        RAISE EXCEPTION 'Todos os campos obrigatórios devem ser fornecidos';
    END IF;

    IF l_preco <= 0 THEN
        RAISE EXCEPTION 'Valor de preço informado é inválido %', l_preco;
    end if;

    IF l_quantidade_estoque < 0 THEN
        RAISE EXCEPTION 'A quantidade em estoque não pode ser negativa';
    END IF;

--     Busca o ID da editora pelo nome e o pais
    SELECT id INTO editora_id FROM Editoras WHERE LOWER(pais) = editora_pais AND LOWER(nome) = editora_nome;

--     Verifica se existe editora com os atributos informados, se não existir, salva a editora e salva seu id
    IF editora_id IS NULL THEN
        INSERT INTO Editoras (pais, nome) VALUES (editora_pais, editora_nome) RETURNING id INTO editora_id;
    end if;

--     Busca o ID da categoria pelo nome
    SELECT id INTO categoria_id FROM  Categorias WHERE LOWER(nome) = categoria_nome;

--     Verifica se existe categoria com o nome informado, se não existir, salva a categoria e salva seu id
    IF categoria_id IS NULL THEN
        INSERT INTO Categorias (nome) VALUES ( categoria_nome) RETURNING id INTO categoria_id;
    end if;

    BEGIN
        INSERT INTO Livros(titulo, autor_id, isbn, editora_id, preco, quantidade_estoque, categoria_id)
        VALUES (l_titulo, l_autor_id, l_isbn, editora_id, l_preco, l_quantidade_estoque, categoria_id);

        RAISE NOTICE 'LIVRO INSERIDO COM SUCESSO';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE EXCEPTION 'Já existe um livro com o ISBN "%"', l_isbn
            USING ERRCODE = 'P0002'; -- P0002 -> Violação de contraint
        WHEN foreign_key_violation THEN
            RAISE EXCEPTION 'Autor com id "%" não existe', l_autor_id
            USING ERRCODE = '23503'; -- 23503 -> Violação de chave ESTRANGEIRA
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Erro ao inserir livro: %', SQLERRM;
    END;
END;
$$;