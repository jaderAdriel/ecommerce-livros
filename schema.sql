CREATE TABLE IF NOT EXISTS Autores (
    id SERIAL,
    nome VARCHAR(100) NOT NULL,
    nacionalidade VARCHAR(60),
    data_nascimento DATE,

    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS Enderecos (
	id SERIAL,
	rua VARCHAR(100) NOT NULL,
	numero VARCHAR(50),
	complemento VARCHAR(255),
	bairro VARCHAR(58),
	cidade VARCHAR(168) NOT NULL,
	estado VARCHAR(59) NOT NULL,
	PRIMARY KEY (id)
);
CREATE INDEX idx_enderecos_estado ON Enderecos(estado);
CREATE INDEX idx_enderecos_cidade ON Enderecos(cidade);


CREATE TABLE IF NOT EXISTS Editoras (
    id SERIAL,
    nome VARCHAR(100) NOT NULL UNIQUE,
    pais VARCHAR(50) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT unq_nome_pais_editora UNIQUE (nome, pais)
);

CREATE TABLE IF NOT EXISTS Categorias (
    id SERIAL,
    nome VARCHAR(100) NOT NULL,

    PRIMARY KEY (id)
);

CREATE DOMAIN ISBN AS VARCHAR(13);

CREATE TABLE IF NOT EXISTS  Livros (
    id SERIAL,
    titulo VARCHAR(124) NOT NULL,
    autor_id INTEGER NOT NULL,
    ISBN ISBN NOT NULL UNIQUE,
    editora_id INTEGER NOT NULL,
    preco DECIMAL(10,2) NOT NULL,
    quantidade_estoque INTEGER default 0,
    categoria_id INTEGER,

    CONSTRAINT chk_livros_preco CHECK (preco > 0),
	CONSTRAINT chk_livros_quantidade_estoque CHECK (quantidade_estoque >= 0),

    FOREIGN KEY (autor_id) REFERENCES Autores(id),
    FOREIGN KEY (editora_id) REFERENCES Editoras(id),
    FOREIGN KEY (categoria_id) REFERENCES Categorias(id) ON DELETE SET NULL,
    PRIMARY KEY (id)
);
CREATE INDEX idx_livros_autor_id ON Livros(autor_id);
CREATE INDEX idx_livros_editora_id ON Livros(editora_id);
CREATE INDEX idx_livros_categoria_id ON Livros(categoria_id);
CREATE INDEX idx_quantidade_estoque ON Livros(quantidade_estoque);


CREATE TABLE IF NOT EXISTS Clientes (
    id SERIAL,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(40) NOT NULL UNIQUE,
    senha TEXT NOT NULL,
    endereco_id INTEGER NOT NULL,

    FOREIGN KEY (endereco_id) REFERENCES Enderecos(id),
    PRIMARY KEY (id)
);

CREATE TYPE PEDIDO_STATUS_ENUM as ENUM ('ABERTO', 'ENVIADO', 'ENTREGUE', 'CANCELADO');
CREATE TABLE IF NOT EXISTS Pedidos (
    id SERIAL,
    cliente_id INTEGER NOT NULL,
    data_pedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status PEDIDO_STATUS_ENUM DEFAULT 'ABERTO',
    frete DECIMAL(10,2) NOT NULL DEFAULT 0,

    FOREIGN KEY (cliente_id) REFERENCES Clientes(id),
    PRIMARY KEY (id)
);

CREATE INDEX idx_pedidos_cliente_id ON Pedidos(cliente_id);
CREATE INDEX idx_data_pedido ON Pedidos(data_pedido);

CREATE TABLE IF NOT EXISTS Itens_Pedido (
    id SERIAL,
    pedido_id INTEGER NOT NULL,
    livro_id INTEGER NOT NULL,
    quantidade INTEGER NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,

    CONSTRAINT chk_itens_pedido_preco_unitario CHECK (preco_unitario > 0),
	CONSTRAINT chk_itens_pedido_quantidade CHECK (quantidade > 0),

    FOREIGN KEY (pedido_id) REFERENCES Pedidos(id),
    FOREIGN KEY (livro_id) REFERENCES Livros(id),
    PRIMARY KEY (id)
);

CREATE INDEX idx_itens_pedido_pedido_id ON Itens_Pedido(pedido_id);
CREATE INDEX idx_itens_pedido_livro_id ON Itens_Pedido(livro_id);


CREATE TABLE IF NOT EXISTS Carrinho(
    id SERIAL,
    cliente_id INTEGER NOT NULL,
    livro_id INTEGER NOT NULL,
    quantidade INTEGER NOT NULL,

    FOREIGN KEY (cliente_id) REFERENCES Clientes(id),
    FOREIGN KEY (livro_id) REFERENCES Livros(id),
    CONSTRAINT unq_cliente_livro_carrinho UNIQUE (cliente_id, livro_id),

    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS relatorio_vendas_categoria (
    gerado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP PRIMARY KEY,
    categoria VARCHAR,
    total_vendido INT,
    total_faturado NUMERIC(12,2)
);
