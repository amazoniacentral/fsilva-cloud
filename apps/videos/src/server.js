const express = require('express');
const fs = require('fs');
const path = require('path');
const cors = require('cors');
const ffmpeg = require('fluent-ffmpeg');
const db = require('./queue');

const app = express();

app.use(cors());
// Aumentei o limite caso precise enviar metadados maiores, mas o padrão atual já atende
app.use(express.raw({ type: 'application/octet-stream', limit: '100mb' }));
app.use(express.static(path.join(__dirname, '../public')));

const VIDEO_DIR = '/var/www/videos';
const UPLOAD_DIR = '/app/uploads';
app.use('/videos', express.static(VIDEO_DIR));

if (!fs.existsSync(VIDEO_DIR)) fs.mkdirSync(VIDEO_DIR, { recursive: true });
if (!fs.existsSync(UPLOAD_DIR)) fs.mkdirSync(UPLOAD_DIR, { recursive: true });

const getFolderSize = (dirPath) => {
    let totalSize = 0;
    const files = fs.readdirSync(dirPath);
    for (const file of files) {
        const filePath = path.join(dirPath, file);
        const stats = fs.statSync(filePath);
        if (stats.isDirectory()) {
            totalSize += getFolderSize(filePath);
        } else {
            totalSize += stats.size;
        }
    }
    return totalSize;
};

// --- LÓGICA DA FILA ---
const processQueue = async () => {
    const isProcessing = db.prepare("SELECT id FROM queue WHERE status = 'PROCESSING'").get();
    if (isProcessing) return;

    const task = db.prepare("SELECT * FROM queue WHERE status = 'PENDING' LIMIT 1").get();
    if (!task) return;

    db.prepare("UPDATE queue SET status = 'PROCESSING' WHERE id = ?").run(task.id);
    console.log(`[FILA] Iniciando: ${task.filename}`);

    ffmpeg(task.filePath)
        .inputOptions(['-threads 2'])
        .outputOptions([
            '-preset', 'veryfast',
            '-g', '48', '-keyint_min', '48', '-sc_threshold', '0',
            '-map', '0:v', '-map', '0:a?', '-map', '0:v', '-map', '0:a?',
            '-map', '0:v', '-map', '0:a?', '-map', '0:v', '-map', '0:a?',
            '-c:v', 'libx264', '-c:a', 'aac', '-b:a', '128k',
            '-filter:v:0', 'scale=-2:1080', '-filter:v:1', 'scale=-2:720',
            '-filter:v:2', 'scale=-2:480', '-filter:v:3', 'scale=-2:360',
            '-var_stream_map', 'v:0,a:0 v:1,a:1 v:2,a:2 v:3,a:3',
            '-b:v:0', '5000k', '-b:v:1', '2500k', '-b:v:2', '1200k', '-b:v:3', '800k',
            '-f', 'hls', '-hls_list_size', '0',
            '-hls_segment_filename', `${task.targetDir}/v%v/seg_%03d.ts`
        ])
        .output(`${task.targetDir}/v%v/playlist.m3u8`)
        .on('error', (err) => {
            console.error('Erro FFmpeg:', err.message);
            db.prepare("UPDATE queue SET status = 'PENDING' WHERE id = ?").run(task.id);
            if (fs.existsSync(task.filePath)) fs.unlinkSync(task.filePath);
        })
        .on('end', () => {
            const masterPlaylist = `#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=5000000,RESOLUTION=1920x1080
v0/playlist.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=2500000,RESOLUTION=1280x720
v1/playlist.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=1200000,RESOLUTION=854x480
v2/playlist.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=800000,RESOLUTION=640x360
v3/playlist.m3u8`;
            fs.writeFileSync(path.join(task.targetDir, 'master.m3u8'), masterPlaylist);

            const sizeInBytes = getFolderSize(task.targetDir);
            const metadata = {
                id: path.basename(task.targetDir),
                titulo: task.titulo, // <--- O Título agora vem do banco
                dataCriacao: new Date().toISOString(),
                tamanhoBytes: sizeInBytes,
                tamanhoMB: (sizeInBytes / (1024 * 1024)).toFixed(2)
            };
            fs.writeFileSync(path.join(task.targetDir, 'metadata.json'), JSON.stringify(metadata));

            console.log(`[FILA] Finalizado: ${task.filename}`);
            if (fs.existsSync(task.filePath)) fs.unlinkSync(task.filePath);
            
            db.prepare("DELETE FROM queue WHERE id = ?").run(task.id);
            processQueue(); 
        })
        .run();
};

app.post('/upload-chunk', (req, res) => {
    const filename = req.headers['x-filename'];
    const chunkIndex = parseInt(req.headers['x-chunk-index']);
    const isLast = req.headers['x-is-last'] === 'true';
    const titulo = req.headers['x-titulo'] || 'Sem Título'; // <--- RECEBENDO O TÍTULO
    
    if (!filename) return res.status(400).send('Nome do arquivo faltando');

    const filePath = path.join(UPLOAD_DIR, filename);

    if (chunkIndex === 0) fs.writeFileSync(filePath, req.body);
    else fs.appendFileSync(filePath, req.body);

    if (isLast) {
        const targetDir = path.join(VIDEO_DIR, Date.now().toString());
        for (let i = 0; i < 4; i++) fs.mkdirSync(path.join(targetDir, `v${i}`), { recursive: true });

        // Adiciona na fila com o título
        db.prepare("INSERT INTO queue (filePath, targetDir, filename, titulo) VALUES (?, ?, ?, ?)")
          .run(filePath, targetDir, filename, titulo);

        processQueue();
        return res.send({ status: 'na_fila' });
    }
    res.send({ status: 'recebido' });
});

app.get('/videos-list', (req, res) => {
    try {
        const folders = fs.readdirSync(VIDEO_DIR);
        const videoList = folders.map(folderName => {
            const folderPath = path.join(VIDEO_DIR, folderName);
            const stats = fs.statSync(folderPath);
            const metaPath = path.join(folderPath, 'metadata.json');
            if (!stats.isDirectory()) return null;

            let metadata = {};
            if (fs.existsSync(metaPath)) metadata = JSON.parse(fs.readFileSync(metaPath, 'utf8'));

            return {
                id: folderName,
                fileName: `${folderName}/master.m3u8`,
                ...metadata,
                codificado: fs.existsSync(path.join(folderPath, 'master.m3u8'))
            };
        })
        .filter(item => item !== null)
        .sort((a, b) => new Date(b.dataCriacao) - new Date(a.dataCriacao));

        res.json(videoList);
    } catch (error) {
        res.status(500).json({ error: 'Erro ao listar' });
    }
});

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Servidor rodando em http://0.0.0.0:${PORT}`);
    db.prepare("UPDATE queue SET status = 'PENDING' WHERE status = 'PROCESSING'").run();
    processQueue();
});
