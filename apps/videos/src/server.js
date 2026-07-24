const express = require('express');
const multer = require('multer');
const ffmpeg = require('fluent-ffmpeg');
const fs = require('fs');
const path = require('path');
const cors = require('cors');

const app = express();

// Middlewares básicos para permitir conexões do front e JSON
app.use(cors());
app.use(express.json());

// Constantes de diretório (caminhos absolutos dentro do contêiner)
const VIDEO_DIR = '/var/www/videos';
const UPLOAD_DIR = '/app/uploads';

// Garantir que as pastas existam ao iniciar o servidor
if (!fs.existsSync(VIDEO_DIR)) fs.mkdirSync(VIDEO_DIR, { recursive: true });
if (!fs.existsSync(UPLOAD_DIR)) fs.mkdirSync(UPLOAD_DIR, { recursive: true });

// Configuração do Multer para salvar temporariamente os arquivos enviados
const upload = multer({ dest: UPLOAD_DIR });

app.post('/upload', upload.single('video'), (req, res) => {
    if (!req.file) {
        return res.status(400).send({ status: 'erro', message: 'Nenhum arquivo de vídeo foi enviado.' });
    }

    const inputPath = req.file.path;
    const folderId = Date.now().toString();
    const targetDir = path.join(VIDEO_DIR, folderId);
    
    // Cria a pasta específica para este processamento
    fs.mkdirSync(targetDir);

    console.log(`Iniciando conversão de vídeo para streaming. Pasta: ${folderId}`);

    // Configuração do processamento com FFmpeg
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
        .on('start', (commandLine) => {
            console.log('FFmpeg rodando: ' + commandLine);
        })
        .on('error', (err) => {
            console.error('Erro na conversão: ' + err.message);
            // Remove o arquivo bruto se der erro
            if (fs.existsSync(inputPath)) fs.unlinkSync(inputPath);
            res.status(500).send({ status: 'erro', message: 'Falha ao processar vídeo.' });
        })
        .on('end', () => {
            console.log('Processamento concluído com sucesso.');
            // Remove o arquivo bruto após terminar
            if (fs.existsSync(inputPath)) fs.unlinkSync(inputPath);
            res.send({ status: 'sucesso', url: `/videos/${folderId}/playlist.m3u8` });
        })
        .run();
});

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Servidor de processamento rodando em http://localhost:${PORT}`);
});
