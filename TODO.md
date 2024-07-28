## Server
- Continue implementing (basic) error handling.
  - Review `session.rs` and `login.rs`.
  - Turn all (or most) `internal-server-error`s into log messages and send no message.
            
- Globally all API responses should contain an `expires_at` field. Maybe also an `error` field.
  - Maybe add a middleware to make sure all API responses follow this requirement and refresh session.

- Use rust integration tests (for selected use cases).

## Client
- Adapt error handling to server errors
- Use sessions.