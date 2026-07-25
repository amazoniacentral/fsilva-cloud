const Database = require('better-sqlite3');
const fs = require('fs');
const path = require('path');

// Diretório privado dentro do container
const DB_DIR = '/app/data';

// Garante que a pasta exista para o arquivo não falhar
if (!fs.existsSync(DB_DIR)) {
    fs.mkdirSync(DB_DIR, { recursive: true });
}

// Inicializa o banco dentro do sistema de arquivos do container
const db = new Database(path.join(DB_DIR, 'queue.db'));

// Cria a tabela
db.exec(`
  CREATE TABLE IF NOT EXISTS queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    filePath TEXT,
    targetDir TEXT,
    filename TEXT,
    status TEXT DEFAULT 'PENDING'
  )
`);

module.exports = db;
