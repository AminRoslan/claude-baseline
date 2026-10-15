---
pack: ingestion
agent: ingestion-reviewer
escalate_in_qa_pass: true
---
Enable for: products that import user files or external data — document upload, OCR, bank/statement/invoice parsing, CSV/Excel imports, email ingestion, ETL from partner APIs.

Route ingestion-reviewer when the diff touches:
- paths/names containing: upload, import, ingest, parse, parser, ocr, extract, normalize, normalise, csv, xlsx, pdf, statement, feed, etl, mapping
- parsing rules, format detection, field extraction or normalisation
