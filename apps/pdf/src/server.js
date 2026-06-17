const express = require("express");
const { generatePDF } = require("./pdf");
const fs = require("fs").promises;
const path = require("path");

const app = express();
app.use(express.json({ limit: "10mb" }));

app.post("/pdf", async (req, res) => {
  try {
    const { template, filename, documentId } = req.body;
    const pdf = await generatePDF(template || "report.html", req.body);

    // Define o nome do arquivo
    const nameOfFile = filename || "report.pdf";
    
    if (documentId){
        // Define o caminho absoluto onde o arquivo será salvo no disco
        // Neste exemplo, ele salvará em uma pasta chamada "output" dentro do WORKDIR
        const outputDir = path.join(__dirname, "output");
        const filePath = path.join(outputDir, `${documentId}.pdf`);
    
        // Garante que a pasta de destino exista no disco, se não existir, cria ela
        await fs.mkdir(outputDir, { recursive: true });
    
        // Grava o arquivo binário do PDF no caminho especificado
        await fs.writeFile(filePath, pdf);
    }

    res.set({
      "Content-Type": "application/pdf",
      "Content-Disposition": `inline; filename=${nameOfFile}`,
    });

    res.send(pdf);
  } catch (err) {
    console.error(err);
    res.status(500).send("Erro ao gerar PDF");
  }
});

app.listen(3000, () => {
  console.log("PDF Service rodando na porta 3000");
});
