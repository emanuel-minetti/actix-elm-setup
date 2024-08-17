## Server
- Continue implementing (basic) error handling.
  - Add 'Not Found'.
  - Implement (basic) logging.
    - Turn all (or most) `internal-server-error`s and login related messages into log messages and send no message.

- Use rust integration tests (for selected use cases).

## Client
- Adapt error handling to server errors
- Use sessions.