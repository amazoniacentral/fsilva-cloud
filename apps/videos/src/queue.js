const Database = require('better-sqlite3');
const fs = require('fs');
const path = require('path');

const DB_DIR = '/app/data';

if (!fs.existsSync(DB_DIR)) {
    fs.mkdirSync(DB_DIR, { recursive: true });
}

const db = new Database(path.join(DB_DIR, 'queue.db'));

// 1. Cria a tabela principal
db.exec(`
  CREATE TABLE IF NOT EXISTS queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    filePath TEXT,
    targetDir TEXT,
    filename TEXT,
    status TEXT DEFAULT 'PENDING'
  )
`);

// 2. Migração: Adiciona a coluna 'titulo' caso ela não exista
try {
    db.prepare("ALTER TABLE queue ADD COLUMN titulo TEXT").run();
    console.log("[DB] Coluna 'titulo' adicionada com sucesso.");
} catch (e) {
    // Se der erro, é porque a coluna provavelmente já existe, então ignoramos
    if (!e.message.includes("duplicate column name")) {
        console.error("[DB] Erro ao tentar adicionar coluna:", e.message);
    }
}

module.exports = db;
