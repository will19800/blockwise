# Blockwise relay

The relay assigns monotonically increasing server sequence numbers, persists operations,
and broadcasts opaque payloads. It never interprets CRDT content.

M0 provides the process, package boundaries, health endpoint, and container scaffold.
WebSocket synchronization and SQLite persistence arrive in M5.

## Run locally

```sh
go run ./cmd/relay
```

The process listens on `:8080` by default. Override it with
`BLOCKWISE_RELAY_ADDR=127.0.0.1:9090`. Check readiness with:

```sh
curl http://localhost:8080/healthz
```

## Test

```sh
go test ./...
go vet ./...
```

## Container

```sh
docker compose up --build
```

