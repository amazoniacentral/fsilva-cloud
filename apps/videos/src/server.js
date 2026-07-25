const express = require('express');
const fs = require('fs');
const path = require('path');
const cors = require('cors');
const ffmpeg = require('fluent-ffmpeg');

const app = express();

// Middleware: Aceita dados binários brutos (chunked)
// Aumentamos o limite para garantir que o bloco chegue
app.use(express.raw({ type: 'application/octet-stream', limit: '20mb' }));
app.use(cors());

// Diretórios
const VIDEO_DIR = '/var/www/videos';
const UPLOAD_DIR = '/app/uploads';

// Garantir que pastas existam
if (!fs.existsSync(VIDEO_DIR)) fs.mkdirSync(VIDEO_DIR, { recursive: true });
if (!fs.existsSync(UPLOAD_DIR)) fs.mkdirSync(UPLOAD_DIR, { recursive: true });

app.post('/upload-chunk', (req, res) => {
    const filename = req.headers['x-filename'];
    const chunkIndex = parseInt(req.headers['x-chunk-index']);
    const isLast = req.headers['x-is-last'] === 'true';
    
    if (!filename) return res.status(400).send('Nome do arquivo faltando');

    const filePath = path.join(UPLOAD_DIR, filename);

    // Se for o primeiro pedaço, cria o arquivo. Se não, faz append.
    if (chunkIndex === 0) {
        fs.writeFileSync(filePath, req.body);
    } else {
        fs.appendFileSync(filePath, req.body);
    }

    if (isLast) {
        console.log(`Upload concluído: ${filename}. Iniciando processamento...`);
        
        // Aqui chamamos sua lógica de conversão original
        const inputPath = filePath;
        const folderId = Date.now().toString();
        const targetDir = path.join(VIDEO_DIR, folderId);
        
        fs.mkdirSync(targetDir);

        ffmpeg(inputPath)
            .inputOptions(['-threads 1']) 
            .outputOptions([
                '-preset veryfast',
                '-g 48', '-keyint_min 48', '-sc_threshold 0',
                '-map 0:v:0', '-map 0:v:0', '-map 0:v:0', '-map 0:v:0',
                '-c:v libx264',
                '-b:v:0 5000k', '-s:v:0 1920x1080',
                '-b:v:1 2500k', '-s:v:1 1280x720',
                '-b:v:2 1200k', '-s:v:2 854x480',
                '-b:v:3 800k',  '-s:v:3 640x360',
                '-var_stream_map "v:0,v:1,v:2,v:3"',
                '-vf', "scale='if(gt(iw,ih),min(1920,iw),-2)':'if(gt(iw,ih),-2,min(1080,ih))'",
                '-f hls',
                '-hls_list_size 0',
                '-hls_segment_filename', `${targetDir}/v%v/seg_%03d.ts`
            ])
            .output(`${targetDir}/v%v/playlist.m3u8`)
            .on('error', (err) => {
                console.error('Erro FFmpeg:', err.message);
                if (fs.existsSync(inputPath)) fs.unlinkSync(inputPath);
            })
            .on('end', () => {
                console.log('Processamento concluído.');
                if (fs.existsSync(inputPath)) fs.unlinkSync(inputPath);
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
