---
pack: privacy
agent: privacy-reviewer
escalate_in_qa_pass: false
---
Enable for: products holding significant personal data or operating under a data-protection law the overlay names (e.g. GDPR, PDPA, CCPA), and anything with health, biometric, children's, financial-identity or location data.

Route privacy-reviewer when the diff touches:
- new or changed personal-data fields (identity numbers, contact details, location, health, biometrics, financial identity, minors' data)
- data exports, analytics/tracking, third-party SDKs or data sharing, cross-region storage
- consent, preferences, retention/deletion, data-subject-request flows
