## Server
- Continue implementing (basic) error handling. 
    - Gracefully response to invalid session tokens. Responding with status 401.
            
- Globally all API responses should contain an `error` field along an `expires_at` field.
  - Add a middleware to make sure all API responses follow this requirement and refresh session.

- Use rust integration tests (for selected use cases).

## Client
- Adapt error handling to server errors
- Use sessions.