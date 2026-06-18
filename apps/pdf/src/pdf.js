const fs = require("fs");
const path = require("path");
const handlebars = require("handlebars");
const puppeteer = require("puppeteer");

// 👇 registra o helper ANTES de compilar o template
handlebars.registerHelper("money", (value) => {
  return Number(value || 0).toLocaleString("pt-BR", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  });
});

handlebars.registerHelper("date", (value) => {
  if (!value) return "";

  return new Date(value).toLocaleDateString("pt-BR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  });
});

async function generateHTML(templateString, data) {
  const template = handlebars.compile(templateString);
  return template(data);
}

async function generatePDF(templateName, data) {
  const filePath = path.join(__dirname, "templates", templateName);
  const htmlTemplate = fs.readFileSync(filePath, "utf8");

  const template = handlebars.compile(htmlTemplate);
  const html = template(data);

  const browser = await puppeteer.launch({
    headless: "new",
    args: [
      "--no-sandbox", 
      "--disable-setuid-sandbox",
      "--disable-dev-shm-usage", // Evita travamentos por falta de memória em containers Docker
      "--disable-accelerated-2d-canvas",
      "--disable-gpu",
      "--no-first-run",
      "--no-zygote",
      "--single-process" // Diminui drasticamente o consumo de recursos na VPS
    ],
  });

  const page = await browser.newPage();
  
  // Bloqueia requisições externas de rede para impedir lentidão no Docker
  await page.setRequestInterception(true);
  page.on("request", (req) => {
    const resourceType = req.resourceType();
    // Permite apenas o HTML local e dados em Base64 (data:)
    if (req.url().startsWith("data:") || resourceType === "document") {
      req.continue();
    } else if (resourceType === "stylesheet" || resourceType === "font" || resourceType === "image") {
      // Aborta estilos, fontes e imagens externas que destroem a performance da renderização
      req.abort();
    } else {
      req.continue();
    }
  });

  // Define o timeout como 0 (infinito) na navegação para impedir o colapso dos 30 segundos padrão
  await page.setContent(html, { 
    waitUntil: "domcontentloaded",
    timeout: 0 
  });

  const pdf = await page.pdf({
    format: "A4",
    printBackground: true,
    displayHeaderFooter: true,

    // IMPORTANTE: Imagens em headerTemplate só funcionam de forma segura e sem travar a rede 
    // se forem injetadas via String Base64 (data:image/png;base64,...). Não use URLs HTTP/HTTPS aqui.
    headerTemplate: `
      <div style="
        width: 100%;
        padding: 0 20px;
        display: flex;
        align-items: center;
        justify-content: space-between;
        font-size: 10px;
        color: #444;
        border-bottom: 1px solid #eee;
      ">
        <div style="display:flex; align-items:center; gap:10px;">
          <img src="${data.logo || ''}" style="width:28px; height:28px; object-fit:contain;" />
          <strong style="font-size:11px;">${data.company || "Sistema SaaS"}</strong>
        </div>

        <div style="font-size:11px; font-weight:600; color:#222;">
          ${data.title || "Documento"}
        </div>

        <div style="font-size:9px; color:#888;">
          ${new Date().toLocaleDateString("pt-BR")}
        </div>
      </div>
    `,

    footerTemplate: `
      <div style="
        width: 100%;
        padding: 0 20px;
        display: flex;
        justify-content: space-between;
        align-items: center;
        font-size: 9px;
        color: #666;
        border-top: 1px solid #eee;
      ">

        <div style="display:flex; flex-direction:column;">
          <span style="font-weight:600; color:#333;">
            ${data.company || "Sistema SaaS"}
          </span>
          <span style="font-size:8px; color:#999;">
            Documento gerado automaticamente
          </span>
        </div>

        <div style="text-align:center; font-size:9px; color:#888;">
          Página <span class="pageNumber"></span> de <span class="totalPages"></span>
        </div>

        <div style="font-size:8px; color:#999;">
          ID: ${data.documentId || "N/A"}
        </div>

      </div>
    `,

    margin: {
      top: "90px",
      bottom: "90px",
      left: "20px",
      right: "20px",
    },
    timeout: 0 // Garante que a geração do PDF também não sofra timeout padrão do Puppeteer
  });

  await browser.close();

  return pdf;
}

module.exports = { generatePDF };
