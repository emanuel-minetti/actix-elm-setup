## Server
- Use HTTP header `Authorisation: Bearer ...` instead of `Cookie session_token=...`.
- Continue implementing (basic) error handling. 
    - Gracefully response to invalid session tokens. Choose one of:
            
        - Globally all API responses should contain an `error` field along an `expires_at` field.
          - Add a way (middleware) to make sure all API responses follow this requirement.
        - Responding with status 401.
- Use rust integration tests (for selected use cases).

## Client
- Adapt error handling to server errors
- Use sessions.