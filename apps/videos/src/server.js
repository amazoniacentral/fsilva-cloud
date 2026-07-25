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
            .inputOptions(['-threads 1'])
            .outputOptions([
                '-preset', 'veryfast',
                '-g', '48', '-keyint_min', '48', '-sc_threshold', '0',
                '-map', '0:v', '-map', '0:a?', '-map', '0:v', '-map', '0:a?',
                '-map', '0:v', '-map', '0:a?', '-map', '0:v', '-map', '0:a?',
                '-c:v', 'libx264',
                '-c:a', 'aac',
                '-b:a', '128k',
                '-filter:v:0', 'scale=-2:1080',
                '-filter:v:1', 'scale=-2:720',
                '-filter:v:2', 'scale=-2:480',
                '-filter:v:3', 'scale=-2:360',
                '-var_stream_map', 'v:0,a:0 v:1,a:1 v:2,a:2 v:3,a:3',
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
                if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
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
                fs.writeFileSync(path.join(targetDir, 'master.m3u8'), masterPlaylist);
                console.log(`Processamento concluído: ${folderId}`);
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
