import React, { useState } from 'react';

export default function VideoUpload() {
  const [file, setFile] = useState(null);
  const [status, setStatus] = useState('');
  const [isUploading, setIsUploading] = useState(false);

  const handleFileChange = (e) => {
    setFile(e.target.files[0]);
  };

  const handleUpload = async () => {
    if (!file) {
      alert('Por favor, selecione um arquivo de vídeo.');
      return;
    }

    setIsUploading(true);
    setStatus('Enviando e processando... aguarde.');

    const formData = new FormData();
    formData.append('video', file);

    try {
      const response = await fetch('http://localhost:3010/upload', {
        method: 'POST',
        body: formData,
      });

      const data = await response.json();

      if (response.ok) {
        setStatus(`Sucesso! URL da Playlist: ${data.url}`);
      } else {
        throw new Error(data.message || 'Erro ao enviar vídeo.');
      }
    } catch (error) {
      setStatus(`Erro: ${error.message}`);
    } finally {
      setIsUploading(false);
    }
  };

  return (
    <div style={{ padding: '20px', fontFamily: 'sans-serif' }}>
      <h1>Enviar Vídeo</h1>
      
      <input 
        type="file" 
        accept="video/*" 
        onChange={handleFileChange} 
        disabled={isUploading} 
      />
      
      <button 
        onClick={handleUpload} 
        disabled={isUploading || !file}
        style={{ marginLeft: '10px' }}
      >
        {isUploading ? 'Processando...' : 'Enviar'}
      </button>

      <div style={{ marginTop: '20px', fontWeight: 'bold' }}>
        {status}
      </div>
    </div>
  );
}
