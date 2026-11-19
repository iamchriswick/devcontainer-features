## Notes

Add the following to your `devcontainer.json` if you'd like to limit the persistent volume only to this Dev Container:

```json
"mounts": [
	{
		"source": "claude-code-persistent-${devcontainerId}",
		"target": "/mnt/devcontainers/features/claude-code-persistent",
		"type": "volume"
	}
]
```

## Changelog

| Version | Notes                 |
| ------- | --------------------- |
| 0.1.0   | Development release   |