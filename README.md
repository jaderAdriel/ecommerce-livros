# Banco de Dados para E-commerce de Livros (PostgreSQL)

Este repositório contém o backend de banco de dados completo para um sistema de e-commerce de livros, desenvolvido em PostgreSQL. O projeto inclui o esquema relacional, scripts para popular o banco, lógicas de negócio avançadas com stored procedures e triggers, além de rotinas de administração como gerenciamento de usuários e backups.



## ✨ Funcionalidades

  * **Esquema Relacional Robusto:** Tabelas bem definidas com chaves primárias, estrangeiras, constraints e índices para garantir a integridade e a performance dos dados.
  * **Lógica de Negócio no Banco:** Uso de **Stored Procedures**, **Functions** e **Triggers** para automatizar processos como atualização de estoque e validações complexas.
  * **Visões (Views) para Relatórios:** Views pré-definidas para simplificar consultas comuns, como verificação de estoque baixo ou análise de vendas.
  * **Gerenciamento de Usuários:** Script para criação de roles (usuários) com diferentes níveis de permissão, garantindo a segurança do acesso aos dados.
  * **Rotina de Backup Automatizada:** Um script shell (`backup.sh`) para realizar backups periódicos do banco de dados, garantindo a segurança e a recuperabilidade dos dados.
  * **Dados Iniciais:** Um script (`data.sql`) para popular o banco com dados de exemplo, facilitando testes e o desenvolvimento da aplicação.

## 🗂️ Estrutura do Repositório

```
ecommerce-livros/
├── schema.sql           # Script principal com a criação de todas as tabelas, tipos e índices.
├── data.sql             # Script para inserir dados iniciais de exemplo (mock data).
├── stored_procedure.sql # Definição das Stored Procedures do sistema.
├── function.sql         # Definição das Functions utilizadas, principalmente por triggers.
├── triggers.sql         # Criação dos Triggers que automatizam regras de negócio.
├── views.sql            # Criação das Views para consultas simplificadas.
├── create_users.sh      # Script para criar os usuários (roles) no banco de dados.
└── backup.sh            # Script para automatizar a rotina de backup do banco.
```

## 🚀 Como Usar

Siga os passos abaixo para configurar e inicializar o banco de dados em seu ambiente local.

### Pré-requisitos

  * [PostgreSQL](https://www.postgresql.org/download/) (versão 12 ou superior) instalado e em execução.
  * Um cliente de linha de comando para PostgreSQL, como o `psql`.
  * Permissões de superusuário no PostgreSQL para criar o banco de dados e os usuários.

### Passos de Instalação

1.  **Clone o repositório:**

    ```bash
    git clone https://github.com/SEU-USUARIO/ecommerce-livros.git
    cd ecommerce-livros
    ```

2.  **Crie o Banco de Dados:**
    Abra o `psql` e execute o seguinte comando para criar o banco de dados:

    ```sql
    CREATE DATABASE ecommerce_livros;
    ```

3.  **Execute os Scripts de Criação de Usuários:**
    Torne o script executável e rode-o. Você pode precisar editar o script para ajustar senhas ou nomes de usuário.

    ```bash
    chmod +x create_users.sh
    ./create_users.sh
    ```

4.  **Execute os Scripts SQL:**
    Conecte-se ao banco de dados recém-criado e execute os scripts na ordem correta para garantir que todas as dependências sejam resolvidas.

    ```bash
    # 1. Crie o esquema (tabelas, tipos, índices)
    psql -U seu_usuario -d ecommerce_livros -f schema.sql

    # 2. Crie as Functions (necessárias para os triggers)
    psql -U seu_usuario -d ecommerce_livros -f function.sql

    # 3. Crie os Triggers
    psql -U seu_usuario -d ecommerce_livros -f triggers.sql

    # 4. Crie as Stored Procedures
    psql -U seu_usuario -d ecommerce_livros -f stored_procedure.sql

    # 5. Crie as Views
    psql -U seu_usuario -d ecommerce_livros -f views.sql

    # 6. Insira os dados iniciais
    psql -U seu_usuario -d ecommerce_livros -f data.sql
    ```

    **Pronto\!** Seu banco de dados está configurado e pronto para ser usado.

5.  **Configurando o Backup (Opcional):**
    Edite o script `backup.sh` para ajustar as variáveis (nome do banco, usuário, diretório de backup). Em seguida, torne-o executável e configure um `cronjob` para rodá-lo periodicamente.

    ```bash
    chmod +x backup.sh
    # Exemplo de cronjob para rodar todo dia às 2h da manhã (Politica de backp recomendada)
    # crontab -e
    # 0 2 * * * /caminho/completo/para/ecommerce-livros/backup.sh
    ```

## 📖 Esquema do Banco de Dados

A seguir, a descrição das principais tabelas do sistema.
  * **Autores**: Armazena os dados dos autores dos livros.
  * **Editoras**: Contém as informações das editoras.
  * **Categorias**: Define as categorias ou gêneros dos livros.
  * **Livros**: Tabela central que armazena todos os detalhes dos livros, incluindo preço e estoque.
  * **Clientes**: Guarda as informações dos clientes cadastrados.
  * **Enderecos**: Tabela para armazenar os endereços dos clientes.
  * **Pedidos**: Registra os pedidos feitos pelos clientes, incluindo status e data.
  * **Itens\_Pedido**: Tabela associativa que detalha os livros e quantidades de cada pedido.
  * **Carrinho**: Armazena os itens que um cliente adicionou ao carrinho de compras.
  * **relatorio\_vendas\_categoria**: Tabela desnormalizada para armazenar dados agregados de relatórios.

## 🎓 Créditos e Autores

Este projeto foi desenvolvido como avaliação final para a disciplina de **Tópicos Avançados em Banco de Dados**, do 3º semestre do curso de **Tecnologia em Análise e Desenvolvimento de Sistemas** do **Instituto Federal Baiano (IF Baiano) - Campus Guanambi**.

- **Professor:** Carlos Anderson Oliveira Silva

### 👥 Contribuidores

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/emerss001">
        <img src="https://github.com/emerss001.png?size=100" width="100px;" alt="Foto de Emerson Neves no GitHub"/><br/>
        <sub><b>Emerson Neves</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/jaderAdriel">
        <img src="https://github.com/jaderAdriel.png?size=100" width="100px;" alt="Foto de Jader Adriel no GitHub"/><br/>
        <sub><b>Jader Adriel</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/hcxavier">
        <img src="https://github.com/hcxavier.png?size=100" width="100px;" alt="Foto de Harisson Caio Xavier no GitHub"/><br/>
        <sub><b>Harisson Caio Xavier</b></sub>
      </a>
    </td>
  </tr>
</table>
