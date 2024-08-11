## Server
- Continue implementing (basic) error handling.
  - Review `session.rs`.
  - Add 'Not Found'.
  - Implement (basic) logging.
    - Turn all (or most) `internal-server-error`s and login related messages into log messages and send no message.

- Globally all API responses contain an `error` field. It should be used.

- Use rust integration tests (for selected use cases).

## Client
- Adapt error handling to server errors
- Use sessions.