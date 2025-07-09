#!/bin/bash

DB_NAME="ecommerce-livros"
SUPERUSER_NAME="admin"
SUPERUSER_PASSWORD="passwordDB123"

BACKUP_DIR="$HOME/.bkp/bd/"
DATE=$(date +%F)
FILE="$BACKUP_DIR${DB_NAME}_backup_$DATE.dump"

# Cria diretório se não existir
mkdir -p "$BACKUP_DIR"

# Executa o backup ignorando a tabela de
pg_dump -U "$SUPERUSER_NAME" -F c --exclude-table=relatorio_vendas_categoria -f "$FILE" "$DB_NAME"

# Verifica se o backup foi criado
if [ $? -eq 0 ]; then
    echo "Backup '$DB_NAME' criado com sucesso: $FILE"
else
    echo "Erro ao criar o backup do banco '$DB_NAME'" >&2
    exit 1
fi

# Remove backups com mais de 7 dias
find "$BACKUP_DIR" -name "${DB_NAME}_backup_*.dump" -mtime +7 -exec rm -f {} \;
