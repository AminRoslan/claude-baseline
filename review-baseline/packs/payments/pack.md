---
pack: payments
agent: payments-reviewer
escalate_in_qa_pass: true
---
Enable for: banking, wallets, payment collection/payouts, PSP/gateway integrations, subscriptions/billing, transfers, card or bank-account handling, KYC/AML flows.

Route payments-reviewer when the diff touches:
- paths/names containing: payment, payout, transfer, charge, refund, chargeback, dispute, settlement, wallet, topup, withdraw, subscription, billing, checkout, gateway, psp, webhook, card, iban, account-number, kyc, aml, sanction, limit
- integrations with payment providers or banking APIs
- money-movement state machines or their webhooks/jobs
