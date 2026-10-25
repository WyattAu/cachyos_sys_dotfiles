---
name: api-review
description: API design review — REST/GraphQL endpoint consistency, auth, versioning, error shapes
compatibility: opencode
metadata:
  audience: agents
  workflow: full-stack
---

## What I do

Review API endpoints for design consistency, authentication coverage,
error shape uniformity, versioning strategy, and documentation. The
review checks the CONTRACT, not the implementation logic.

## Workflow

1. **Inventory** — list every route/endpoint with its method, path,
   auth requirement, and response shape
2. **Consistency** — same resource, same shape? `GET /users/:id` and
   `GET /users` should return the same user fields (list may be a
   subset, not a different shape)
3. **Auth coverage** — every mutating endpoint must require auth;
   every public endpoint must be explicitly documented as public
4. **Error shape** — every error response uses the same envelope
   (e.g. `{"error": {"code": "...", "message": "..."}}`); no endpoint
   returns a bare string or a different nesting
5. **Versioning** — are breaking changes behind a version prefix? Is
   the version in the URL (`/v2/`) or a header? Pick one and check
   every route
6. **Status codes** — 200 for success, 201 for create, 204 for delete,
   400 for client error, 401 for no auth, 403 for wrong auth,
   404 for not found, 409 for conflict, 422 for validation, 500 for
   server error. Anything else needs a comment explaining why

## Red flags

- Two endpoints that return the same resource with different field names
- A `DELETE` that returns a body (use 204 No Content)
- An endpoint that returns `200` with `{"error": ...}` in the body
  instead of a 4xx/5xx status
- Auth checked in middleware for some routes but inline for others
- A `POST` that is actually idempotent (should be `PUT`)
- Pagination that changes shape between endpoints

## Output

A table: endpoint | method | auth | status codes | error shape | notes.
Then a prioritized list of inconsistencies with the fix for each.
