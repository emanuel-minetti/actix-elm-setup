## Server
- Continue implementing (basic) error handling.
  - Review `session.rs`.
  - Implement API error handling for middleware. Plan is:
    - Cast `ServiceRequest` to `HttpRequest` and forward all non matching.
    - Remove `EitherBody` and `BoxBody` from deps and code.
    - Return `HttpResponse` (or equivalent) from `return_early` in middleware
  - Turn all (or most) `internal-server-error`s into log messages and send no message.
            
- Globally all API responses contain an `error` field. It should be used.

- Use rust integration tests (for selected use cases).

## Client
- Adapt error handling to server errors
- Use sessions.