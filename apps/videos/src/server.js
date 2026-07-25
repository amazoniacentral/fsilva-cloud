const express = require('express');
const fs = require('fs');
const path = require('path');
const cors = require('cors');
const ffmpeg = require('fluent-ffmpeg');

const app = express();

app.use(cors());
app.use(express.raw({ type: 'application/octet-stream', limit: '100mb' }));

app.use(express.static(path.join(__dirname, '../public')));

const VIDEO_DIR = '/var/www/videos';
const UPLOAD_DIR = '/app/uploads';
app.use('/videos', express.static(VIDEO_DIR));

if (!fs.existsSync(VIDEO_DIR)) fs.mkdirSync(VIDEO_DIR, { recursive: true });
if (!fs.existsSync(UPLOAD_DIR)) fs.mkdirSync(UPLOAD_DIR, { recursive: true });

app.post('/upload-chunk', (req, res) => {
    const filename = req.headers['x-filename'];
    const chunkIndex = parseInt(req.headers['x-chunk-index']);
    const isLast = req.headers['x-is-last'] === 'true';
    
    if (!filename) return res.status(400).send('Nome do arquivo faltando');

    const filePath = path.join(UPLOAD_DIR, filename);

    if (chunkIndex === 0) {
        fs.writeFileSync(filePath, req.body);
    } else {
        fs.appendFileSync(filePath, req.body);
    }

    if (isLast) {
        console.log(`Upload concluído: ${filename}. Processando...`);
        
        const folderId = Date.now().toString();
        const targetDir = path.join(VIDEO_DIR, folderId);
        
        for (let i = 0; i < 4; i++) {
            fs.mkdirSync(path.join(targetDir, `v${i}`), { recursive: true });
        }

        ffmpeg(filePath)
            .outputOptions([
                '-preset', 'veryfast',
                '-g', '48', '-keyint_min', '48', '-sc_threshold', '0',
                '-map', '0:v', '-map', '0:a?',
                '-c:v', 'libx264',
                '-c:a', 'aac',
                '-b:a', '128k',
                // Simplificamos a escala para garantir compatibilidade
                '-vf', 'scale=-2:720',
                '-var_stream_map', 'v:0,a:0',
                '-f', 'hls',
                '-hls_list_size', '0',
                '-hls_segment_filename', `${targetDir}/v0/seg_%03d.ts`
            ])
            .output(`${targetDir}/v0/playlist.m3u8`)
            .on('error', (err, stdout, stderr) => {
                console.error('--- ERRO FFmpeg ---');
                console.error('Mensagem:', err.message);
                console.error('Stderr:', stderr);
                if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
            })
            .on('end', () => {
                console.log(`Sucesso! Vídeo em: /videos/${folderId}/v0/playlist.m3u8`);
                if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
            })
            .run();

        return res.send({ status: 'finalizado' });
    }

    res.send({ status: 'recebido' });
});

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Servidor rodando em http://localhost:${PORT}`);
});
