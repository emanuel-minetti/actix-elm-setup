## Server
- Continue implementing (basic) error handling.
            
- Globally all API responses should contain an `expires_at` field. Maybe also an `error` field.
  - Maybe add a middleware to make sure all API responses follow this requirement and refresh session.

- Use rust integration tests (for selected use cases).

## Client
- Adapt error handling to server errors
- Use sessions.