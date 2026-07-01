---
name: security-review
description: Security review guidance and standards. Use for secrets handling, boundary validation, authentication, transport security, secure logging, and dependency hygiene.
---

# Security Review Standards

## Secrets Management
- Never hardcode secrets, API keys, passwords, or tokens in source code
- Use environment variables or a secrets manager (AWS KMS, Azure Key Vault) for sensitive configuration
- Never log secrets or include them in error messages
- Add secret patterns to `.gitignore` and use pre-commit hooks to prevent accidental commits
- Use separate keys for production and non-production environments — never share between them

## Input Validation
- Validate and sanitise all user input at system boundaries
- Parse and validate inputs in separate steps
- Use parameterised queries for all database operations — never concatenate user input into queries
- Sanitise HTML output to prevent XSS attacks
- Validate file uploads: check type, size, and content — not just the extension

## Authentication and Authorisation
- Use established authentication libraries and frameworks; never roll your own
- Use RBAC (Role-Based Access Control) for all access control decisions
- Enforce the principle of least privilege for all access controls
- Validate authorisation on every request, not just at the UI layer
- Use token-based authentication for internal API calls
- Use OAuth 2.0 for third-party or partner API access
- Use short-lived tokens and implement proper session management
- Log all authentication events and timestamp them

## API Security
- All APIs MUST be accessed over HTTPS — no exceptions
- Send tokens and API keys as HTTP headers, never in URLs (avoids leaking via server logs or Referrer headers)
- Implement rate limiting per consumer on all endpoints
- Validate request content types and reject unexpected formats
- Return generic error messages to clients; log detailed errors server-side

## Encryption and Transport
- Use TLS v1.2 or higher for all network traffic; negotiate TLS v1.3 where possible
- SSL is not permitted — do not use or enable SSL
- Do not mix encrypted and unencrypted transit methods
- Encrypt data at rest using AES-256 or cloud KMS (AWS KMS, Azure Key Vault)
- Use cloud provider key management services for cryptographic key generation and storage
- Cryptographic standards must comply with FIPS, NIST, or ISO

## Logging
- Log all significant security events: authentication, authorisation, access attempts, configuration changes, privilege escalation
- Logs MUST NOT contain PII or sensitive data (passwords, access keys); mask where technically required
- Use structured log formats (JSON preferred)
- Include in all log entries: user/account ID, timestamp, event type, result, and source address
- Forward security logs to the SIEM/SOC platform if possible
- Retain logs: 3 months hot storage, 1 year cold storage minimum
- Store logs outside the production server in a cloud-based logging solution
- Ensure all systems are time-synchronised via NTP for log correlation

## Dependencies
- Keep dependencies up to date; monitor for known vulnerabilities
- Use lock files to pin dependency versions
- Audit new dependencies before adding them
- Scan code at least weekly for vulnerabilities
- Be deliberate about adding new dependencies; prefer native language features where possible

## Infrastructure
- Deploy all infrastructure using Infrastructure as Code
- Use service accounts and CI/CD pipelines for deployment to production; avoid manual changes
- Review and verify infrastructure configurations before deployment
- Scan all pre- and post-processing logic with standard security tools
