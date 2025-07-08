#!/bin/bash

# CONFIGURAÇÕES
DB_NAME="ecommerce-livros"
PG_ADMIN="postgres"             # Usuário administrador do PostgreSQL (existente)
PG_HOST="localhost"
PG_PORT="5432"
SUPERUSER_NAME="admin"
SUPERUSER_PASSWORD="passwordDB123"
LEITOR_NAME="cliente_leitura"
LEITOR_PASSWORD="leitura321"

echo "Criando usuários no PostgreSQL..."

# Criação do superusuário
psql -U "$PG_ADMIN" -h "$PG_HOST" -p "$PG_PORT" -d postgres <<EOF
DO \$\$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_roles WHERE rolname = '${SUPERUSER_NAME}'
    ) THEN
        CREATE ROLE ${SUPERUSER_NAME} WITH
            LOGIN
            SUPERUSER
            CREATEDB
            CREATEROLE
            REPLICATION
            BYPASSRLS
            PASSWORD '${SUPERUSER_PASSWORD}';
    END IF;
END
\$\$;
EOF

# Criação do usuário de leitura
psql -U "$PG_ADMIN" -h "$PG_HOST" -p "$PG_PORT" -d postgres <<EOF
DO \$\$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_roles WHERE rolname = '${LEITOR_NAME}'
    ) THEN
        CREATE ROLE ${LEITOR_NAME} WITH
            LOGIN
            PASSWORD '${LEITOR_PASSWORD}';
    END IF;
END
\$\$;
EOF

# Conceder permissões ao usuário de leitura
psql -U "$PG_ADMIN" -h "$PG_HOST" -p "$PG_PORT" -d "$DB_NAME" <<EOF
GRANT CONNECT ON DATABASE $DB_NAME TO ${LEITOR_NAME};
GRANT USAGE ON SCHEMA public TO ${LEITOR_NAME};
GRANT SELECT ON ALL TABLES IN SCHEMA public TO ${LEITOR_NAME};
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON TABLES TO ${LEITOR_NAME};
EOF

echo "✅ Usuários criados com sucesso!"
