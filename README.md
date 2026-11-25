# Demo iOS (`demo--ios`)

Product + Portal apps for QuickCode site **Demo**.

## Layout

- `Demo/` — product (storefront) + shared shell
- Portal target in the same Xcode project
- `Clients/` — Swift OpenAPI package (`openapi.json` per module; **no committed `GeneratedSources`**)
- `ci_scripts/ci_post_clone.sh` — enables SPM OpenAPIGenerator on Xcode Cloud

## Clients

Unix/Linux generate writes OpenAPI inputs only. Xcode Cloud (or local Xcode) runs the
`swift-openapi-generator` **build plugin** to produce client types at build time.

## Gateway

- Release / Cloud: `https://demo-gateway.quickcode.net`
- Debug: local compose gateway from generation

Do not put backend secrets (JWT, DB, blob) in this repo.