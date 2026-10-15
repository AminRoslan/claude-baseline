---
pack: finance
agent: finance-reviewer
escalate_in_qa_pass: true
---
Enable for: accounting, bookkeeping, payroll, tax, invoicing, lending, investment, financial reporting — anything whose numbers end up in books, filings or statements.

Route finance-reviewer when the diff touches:
- paths/names containing: ledger, journal, account, balance, invoice, bill, payroll, salary, tax, vat, gst, sst, fee, interest, fx, currency, rate, reconcil, statement, report, closing, period
- numeric fields representing money, rates or quantities used in totals
- rule tables, rate constants, calculation engines
