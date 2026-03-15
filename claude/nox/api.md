---
name: api
description: Designs and scaffolds REST or GraphQL API endpoints from a spec or resource name. Use when building new endpoints, expanding an API surface, or generating route boilerplate.
disable-model-invocation: true
argument-hint: "[spec-or-resource]"
metadata:
  author: nox
  version: "2.5"
---

Design and scaffold API endpoints for the specified resource or spec. Detect the project's framework and generate idiomatic route handlers with types, validation, and error handling.

## Process

1. **Detect framework** — Scan project structure to identify the API framework:
   - `app/api/` or `pages/api/` → Next.js (App Router vs Pages Router)
   - `src/routes/` or `express` in deps → Express
   - `main.py` + `fastapi` in deps → FastAPI
   - `urls.py` + `views.py` → Django REST Framework
   - `src/main.rs` + `actix` or `axum` in deps → Rust web framework
   - Other → ask the user
2. **Parse the spec** — Accept input as:
   - A resource name (e.g., `users`, `invoices`) → generate standard CRUD
   - A natural language description (e.g., "endpoint to upload images and return thumbnails")
   - A structured spec (OpenAPI snippet, list of routes)
3. **Generate endpoints** — Create route handlers following framework conventions
4. **Present the plan** — Show the route table before writing any files

## REST Conventions

Follow these unless the project already deviates:

| Method | Route | Action | Status |
|--------|-------|--------|--------|
| GET | `/api/resources` | List all | 200 |
| GET | `/api/resources/:id` | Get one | 200 / 404 |
| POST | `/api/resources` | Create | 201 |
| PUT | `/api/resources/:id` | Full update | 200 / 404 |
| PATCH | `/api/resources/:id` | Partial update | 200 / 404 |
| DELETE | `/api/resources/:id` | Delete | 204 / 404 |

## Generated Code Must Include

- **Type definitions** — Request body, response shape, path params (TypeScript interfaces, Pydantic models, etc.)
- **Input validation** — Zod schemas (TS), Pydantic (Python), or framework-native validation
- **Error handling** — Try/catch with proper HTTP status codes, never expose stack traces
- **Auth guard** — If the project uses auth (Auth0, Clerk, NextAuth, etc.), include middleware or guard checks
- **Response format** — Consistent envelope: `{ data, error, meta }` or match existing project convention

## Rules

- **Plural resource names** — `/api/users` not `/api/user`
- **Kebab-case routes** — `/api/user-profiles` not `/api/userProfiles`
- **No business logic in handlers** — Handlers should call service functions. Scaffold the service layer too.
- **Match existing patterns** — If the project already has API routes, follow their conventions exactly (file naming, error format, middleware usage)
- **Don't over-generate** — If the user asks for one endpoint, don't scaffold five
- **Include the route table** — Always show a summary of what will be created before writing files

## Output

Present a route summary table, then the generated code for each file. Wait for approval before writing.

---
Nox
