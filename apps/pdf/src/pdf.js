const fs = require("fs");
const path = require("path");
const handlebars = require("handlebars");
const puppeteer = require("puppeteer");

async function generatePDF(templateName, data) {
  const filePath = path.join(__dirname, "templates", templateName);
  const htmlTemplate = fs.readFileSync(filePath, "utf8");

  const template = handlebars.compile(htmlTemplate);
  const html = template(data);

  const browser = await puppeteer.launch({
    headless: "new",
    args: ["--no-sandbox", "--disable-setuid-sandbox"],
  });

  const page = await browser.newPage();
  await page.setContent(html, { waitUntil: "networkidle0" });

  const pdf = await page.pdf({
    format: "A4",
    printBackground: true,
    displayHeaderFooter: true,

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
          ${new Date().toLocaleDateString()}
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
  });

  await browser.close();

  return pdf;
}

module.exports = { generatePDF };