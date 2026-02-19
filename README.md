# Roomie

Roomie is a real-time room coordination demo built with Elixir and Phoenix.

It uses:
- Phoenix Channels for realtime messaging (topics like `room:lobby`)
- Phoenix Presence for online user tracking per room
- Ecto + PostgreSQL for message persistence

Ephemeral state (online users) is tracked via Presence.
Durable state (rooms and messages) is stored in Postgres.

## Run locally

Requires a PostgreSQL server running locally, change the `config/dev.exs` to match your local environment configuration.

```bash
mix ecto.create
mix ecto.migrate
mix phx.server
```