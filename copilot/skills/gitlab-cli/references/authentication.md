# GitLab Authentication with glab

## Check Current Status

```bash
# See all authenticated hosts and active user
glab auth status
```

> **Security:** Do NOT use `--show-token` as it exposes credentials in terminal output. To check token scopes programmatically, use the API:
> ```bash
> glab api /personal_access_tokens/self | jq '.scopes'
> ```
> You can also verify scopes in the GitLab UI (User → Preferences → Access Tokens).

## Login Methods

### Interactive Login (Browser OAuth)

```bash
# Login to gitlab.com
glab auth login

# Login to self-hosted instance
glab auth login --hostname gitlab.example.com
```

The interactive flow opens a browser for OAuth. After completing it, glab stores the token in your system keychain or config file.

### Login with Personal Access Token

```bash
# gitlab.com
glab auth login --hostname gitlab.com --token glpat-xxxxxxxxxxxxxxxxxxxx

# Self-hosted
glab auth login --hostname gitlab.example.com --token glpat-xxxxxxxxxxxxxxxxxxxx
```

### Login via Environment Variable

```bash
# Set token for current session (takes priority over stored credentials)
export GITLAB_TOKEN=glpat-xxxxxxxxxxxxxxxxxxxx

# Or for a specific host
export GITLAB_HOST=gitlab.example.com
```

### Non-Interactive / CI Login

```bash
# Pipe token to avoid prompts
echo "glpat-xxxxxxxxxxxxxxxxxxxx" | glab auth login --hostname gitlab.com --stdin
```

## Required Token Scopes

When creating a Personal Access Token in GitLab (User → Preferences → Access Tokens), enable:

| Scope | Required For |
|---|---|
| `api` | Full API access (vulnerabilities, discussions, pipeline triggers) |
| `read_repository` | Reading files and diffs |
| `write_repository` | Creating branches and commits |

For read-only workflows, `read_api` + `read_repository` is sufficient.

## Multi-Host Configuration

glab supports multiple GitLab instances simultaneously. This is useful when you work with both gitlab.com and a self-hosted GitLab instance:

```bash
# Login to multiple hosts
glab auth login --hostname gitlab.com --token <token1>
glab auth login --hostname gitlab.selfhosted.example.com --token <token2>

# Check all configured hosts
glab auth status

# Use a specific host for a command
glab -R gitlab.selfhosted.example.com/group/repo mr list

# Set default host globally (only needed for self-hosted instances)
glab config set host gitlab.selfhosted.example.com
```

> **Note:** If you only use gitlab.com, multi-host configuration is not needed — glab defaults to gitlab.com.

## Logout

```bash
# Logout from gitlab.com
glab auth logout

# Logout from a specific host
glab auth logout --hostname gitlab.example.com
```

## Troubleshooting

```bash
# Verify token is working
glab auth status

# Check token scopes (requires api scope)
glab api /personal_access_tokens/self | jq '.scopes'

# Test API access directly
glab api /user

# If getting "401 Unauthorized", re-authenticate
glab auth logout && glab auth login --hostname gitlab.com --token <new-token>

# If behind a proxy
export HTTPS_PROXY=http://proxy.example.com:8080
glab auth login ...
```

## Configuration File Location

glab stores auth config at:
- macOS/Linux: `~/.config/glab-cli/config.yml`
- Windows: `%APPDATA%\glab-cli\config.yml`

Token is stored in system keychain when available, otherwise in the config file.
