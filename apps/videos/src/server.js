const express = require('express');
const fs = require('fs');
const path = require('path');
const cors = require('cors');
const ffmpeg = require('fluent-ffmpeg');

const app = express();

// Middlewares
app.use(cors());
app.use(express.raw({ type: 'application/octet-stream', limit: '50mb' }));

// Servir o Front-end (pasta 'public' na raiz do projeto)
app.use(express.static(path.join(__dirname, '../public')));

// Servir os Vídeos processados
const VIDEO_DIR = '/var/www/videos';
const UPLOAD_DIR = '/app/uploads';

app.use('/videos', express.static(VIDEO_DIR));

// Garantir que pastas base existam
if (!fs.existsSync(VIDEO_DIR)) fs.mkdirSync(VIDEO_DIR, { recursive: true });
if (!fs.existsSync(UPLOAD_DIR)) fs.mkdirSync(UPLOAD_DIR, { recursive: true });

// Rota de Upload
app.post('/upload-chunk', (req, res) => {
    const filename = req.headers['x-filename'];
    const chunkIndex = parseInt(req.headers['x-chunk-index']);
    const isLast = req.headers['x-is-last'] === 'true';
    
    if (!filename) return res.status(400).send('Nome do arquivo faltando');

    const filePath = path.join(UPLOAD_DIR, filename);

    // Escreve ou anexa os pedaços
    if (chunkIndex === 0) {
        fs.writeFileSync(filePath, req.body);
    } else {
        fs.appendFileSync(filePath, req.body);
    }

    if (isLast) {
        console.log(`Upload concluído: ${filename}. Iniciando processamento...`);
        
        const inputPath = filePath;
        const folderId = Date.now().toString();
        const targetDir = path.join(VIDEO_DIR, folderId);
        
        // CRUCIAL: Cria a pasta raiz e as subpastas v0, v1, v2, v3
        for (let i = 0; i < 4; i++) {
            fs.mkdirSync(path.join(targetDir, `v${i}`), { recursive: true });
        }

        ffmpeg(inputPath)
            .inputOptions(['-threads 1']) 
            .outputOptions([
                '-preset', 'veryfast',
                '-g', '48', '-keyint_min', '48', '-sc_threshold', '0',
                
                // Mapeia vídeo e áudio
                '-map', '0:v', '-map', '0:a?', 
                
                // Codecs
                '-c:v', 'libx264',
                '-c:a', 'aac',
                '-b:a', '128k',
                
                // Escala mantendo proporção original (sem esticar)
                '-vf', 'scale=-2:1080,scale=-2:720,scale=-2:480,scale=-2:360',
                
                // Streaming Multirresolução
                '-var_stream_map', 'v:0,a:0 v:1,a:0 v:2,a:0 v:3,a:0',
                
                // Taxas de bits
                '-b:v:0', '5000k',
                '-b:v:1', '2500k',
                '-b:v:2', '1200k',
                '-b:v:3', '800k',

                '-f', 'hls',
                '-hls_list_size', '0',
                '-hls_segment_filename', `${targetDir}/v%v/seg_%03d.ts`
            ])
            .output(`${targetDir}/v%v/playlist.m3u8`)
            .on('error', (err, stdout, stderr) => {
                console.error('Erro FFmpeg:', err.message);
                console.error('Stderr:', stderr);
                if (fs.existsSync(inputPath)) fs.unlinkSync(inputPath);
            })
            .on('end', () => {
                console.log(`Processamento concluído: ${folderId}`);
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
