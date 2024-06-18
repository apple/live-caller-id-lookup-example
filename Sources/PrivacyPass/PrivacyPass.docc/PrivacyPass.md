# ``PrivacyPass``

Implementation of the Privacy Pass publicly verifiable tokens.

## Overview

[RFC 9576: The Privacy Pass Architecture](https://www.rfc-editor.org/rfc/rfc9576) describes how to use private access tokens. This framework implements publicly verifiable tokens described in [RFC 9578: Privacy Pass Issuance Protocols](https://www.rfc-editor.org/rfc/rfc9578).

## Topics

### Configuration
- ``PrivateKey``
- ``PublicKey``
- ``TokenIssuerDirectory``

### Requesting Tokens
- ``PreparedRequest``
- ``TokenRequest``
- ``TokenResponse``
- ``Token``

### Issuing Tokens
- ``Issuer``

### Verifing Tokens
- ``Verifier``
