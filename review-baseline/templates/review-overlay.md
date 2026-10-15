# Review overlay
<!-- Project facts for reviewers. Keep under ~30 lines. Packs line is maintained by review-pack.ps1. -->

Domain: <one line — what the product does and for whom>
Stack: <e.g. NestJS + MongoDB + React | Django + Postgres | Go + gRPC>
Tenancy: <single-tenant | multi-tenant, scoped by <field>>
Users include minors: <yes | no | unknown>
Jurisdiction: <countries the product operates in>
Regulations in scope: <list confirmed by owner, e.g. "GDPR", "PDPA (MY)", "PCI DSS SAQ-A" — or "not confirmed">
Business timezone: <IANA zone, e.g. Asia/Kuala_Lumpur>
Base branch: <develop | main>
Test command: <e.g. bun run test | pytest | go test ./...>

Packs: <none>

Trust boundaries (force reviewers on these paths):
- <glob> -> <reviewer[, reviewer]>

Skip reviewers: <none | agent names>

Domain rules:
- <e.g. "Money stored as integer minor units; round half-up once at document total">
- <e.g. "Confirmations required before crediting deposits: 12">
