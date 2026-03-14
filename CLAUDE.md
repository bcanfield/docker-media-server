# Development Instructions

See [README](./README.md) for project info.

## Agent API Access

Service API keys are stored in `.claude/settings.json` (gitignored). Copy from `.claude/settings.example.json` and fill in your values.

```bash
cp .claude/settings.example.json .claude/settings.json
```

To query a service API (e.g. Radarr):
```
GET {url}/api/v3/{endpoint}?apikey={apiKey}
```
