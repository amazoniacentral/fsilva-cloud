const express = require("express");
const { generatePDF } = require("./pdf");

const app = express();
app.use(express.json({ limit: "10mb" }));

app.post("/pdf/report", async (req, res) => {
  try {
    const pdf = await generatePDF("report.html", req.body);

    res.set({
      "Content-Type": "application/pdf",
      "Content-Disposition": "inline; filename=report.pdf",
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