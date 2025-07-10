# Claude Configs

## Install MCP Servers

### orm-discovery-mcp-go

https://github.com/usadamasa/orm-discovery-mcp-go

```shell
# Claude Code MCP設定
claude mcp add -s user orm-discovery-mcp-go \
  -e OREILLY_USER_ID="your_email@acm.org" \
  -e OREILLY_PASSWORD="your_password" \
  -e ORM_MCP_GO_TMP_DIR="your/tmp/dir" \
  -- /your/path/to/orm-discovery-mcp-go
```

### playwright-min-network-mcp

https://zenn.dev/moneyforward/articles/55b47975add631

```shell
# playwright-min-network-mcp
claude mcp add -s user network-monitor \
    -- npx -y playwright-min-network-mcp

# playwright
claude mcp add -s user playwright \
    -- npx -y @playwright/mcp --cdp-endpoint http://localhost:9222

# install playwright cmd
npx -g -y install playwright
```

## References

- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
