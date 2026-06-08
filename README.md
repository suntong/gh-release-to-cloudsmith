# GitHub to Cloudsmith Package Sync

Automated tool to download the latest release packages (.deb, .rpm, .apk) from a GitHub repository and push them to Cloudsmith.

## Features

- Downloads the latest release from any GitHub repository
- Supports .deb, .rpm, and Alpine Linux .apk package formats
- Automatically detects and skips Android APK files (not supported by Cloudsmith)
- Uses `file --mime-type` to distinguish Alpine packages from Android APKs
- Automatically pushes packages to Cloudsmith with appropriate repository paths
- Configurable via command-line arguments or environment variables
- Docker support for easy deployment in CI/CD pipelines

## Quick Start

### Using Docker (Recommended)

```bash
# Build the Docker image
./docker-wrapper.sh build

# Run the sync
./docker-wrapper.sh run -r suntong/process_hog_watcher -k your-cloudsmith-api-key

# Or build and run in one step
./docker-wrapper.sh build-run -r suntong/process_hog_watcher -k your-cloudsmith-api-key
```

### Using Shell Script

```bash
# Set your credentials
export GITHUB_REPO="suntong/process_hog_watcher"
export CLOUDSMITH_API_KEY="your-cloudsmith-api-key"

# Run the sync
./github-to-cloudsmith.sh
```

## Usage

### Docker Wrapper (Recommended)

```bash
./docker-wrapper.sh [COMMAND] [OPTIONS]

COMMANDS:
    build                   Build the Docker image
    run                     Run the Docker container
    build-run               Build and run in one step

OPTIONS:
    -r, --repo REPO         GitHub repository in format "owner/repo" (required)
    -w, --workspace REPO    Cloudsmith workspace/repo (default: suntong/repo)
    -k, --api-key KEY       Cloudsmith API key (required)
    -n, --name NAME         Docker image name (default: github-to-cloudsmith)
    -g, --tag TAG           Docker image tag (default: latest)
    --skip-deb              Skip .deb files
    --skip-rpm              Skip .rpm files
    --skip-apk              Skip .apk files
```

### Shell Script

```bash
./github-to-cloudsmith.sh [OPTIONS]

OPTIONS:
    -h, --help              Show help message
    -r, --repo REPO         GitHub repository in format "owner/repo" (required)
    -w, --workspace REPO    Cloudsmith workspace/repo (default: suntong/repo)
    -t, --token TOKEN       GitHub API token (optional for public repos)
    -k, --api-key KEY       Cloudsmith API key (required)
    -d, --download-dir DIR  Download directory (default: /tmp/cloudsmith-sync)
    --skip-deb              Skip .deb files
    --skip-rpm              Skip .rpm files
    --skip-apk              Skip .apk files
```

## Environment Variables

You can set these environment variables instead of using command-line options:

- `GITHUB_REPO`: GitHub repository in **owner/repo** format (e.g., `suntong/process_hog_watcher`)
- `CLOUDSMITH_REPO`: Cloudsmith workspace/repo (default: `suntong/repo`)
- `GITHUB_TOKEN`: GitHub API token (for private repos)
- `CLOUDSMITH_API_KEY`: Cloudsmith API key

## Cloudsmith Repository Paths

The script automatically determines the appropriate Cloudsmith repository path and push format based on package type:

- **Alpine Linux packages** (`.apk` with MIME type `application/gzip`, `application/zstd`, or `application/x-tar`)
  → `{workspace}/alpine/any-version` with format `alpine`
- **Android APK files** (`.apk` with MIME type `application/vnd.android.package-archive` or `application/zip`)
  → Automatically skipped (not supported by Cloudsmith)
- **Debian packages** (`.deb`) → `{workspace}/any-distro/any-version` with format `deb`
- **RPM packages** (`.rpm`) → `{workspace}/any-distro/any-version` with format `rpm`

**Note**: The script uses `file --mime-type` to distinguish between Alpine Linux packages and Android APK files. Only Alpine Linux packages will be pushed to Cloudsmith. The `file` command is required and is included in the Docker image.

## Examples

### Example 1: Docker - Basic Usage

```bash
# Build and run in one step
./docker-wrapper.sh build-run \
    -r suntong/process_hog_watcher \
    -k your-cloudsmith-api-key
```

### Example 2: Docker with Environment Variables

```bash
export GITHUB_REPO=suntong/process_hog_watcher
export CLOUDSMITH_API_KEY=your-cloudsmith-api-key

./docker-wrapper.sh run
```

### Example 3: Direct Docker Run

```bash
docker run --rm \
  -e GITHUB_REPO=suntong/process_hog_watcher \
  -e CLOUDSMITH_API_KEY=$CLOUDSMITH_API_KEY \
  github-to-cloudsmith:latest
```

### Example 4: Shell Script - Basic Usage

```bash
./github-to-cloudsmith.sh \
    -r suntong/process_hog_watcher \
    -k your-cloudsmith-api-key
```

### Example 5: Shell Script with Custom Workspace

```bash
./github-to-cloudsmith.sh \
    -r suntong/process_hog_watcher \
    -w myworkspace/myrepo \
    -k your-cloudsmith-api-key
```

### Example 6: Shell Script - Selective Package Types

```bash
./github-to-cloudsmith.sh \
    -r suntong/process_hog_watcher \
    -k your-cloudsmith-api-key \
    --skip-apk
```

### Example 7: Shell Script - Private Repository

```bash
export GITHUB_REPO=your-username/your-private-repo
export GITHUB_TOKEN=your-github-token
export CLOUDSMITH_API_KEY=your-cloudsmith-api-key

./github-to-cloudsmith.sh
```

## Requirements

### Docker (Recommended)
- Docker installed and running

### Shell Script
- Bash
- curl
- jq
- **file** command (for MIME type detection)
- Cloudsmith CLI (or use Docker version)

## Getting Cloudsmith API Key

1. Go to [Cloudsmith API Keys](https://app.cloudsmith.com/settings/api-keys)
2. Copy your API key
3. Set it as environment variable: `export CLOUDSMITH_API_KEY=your-key`

## Getting GitHub Token (Optional)

For private repositories, you need a GitHub token:

1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Generate a new token with `repo` scope
3. Set it as environment variable: `export GITHUB_TOKEN=your-token`

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Sync to Cloudsmith

on:
  workflow_dispatch:
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Sync to Cloudsmith
        env:
          GITHUB_REPO: suntong/process_hog_watcher
          CLOUDSMITH_API_KEY: ${{ secrets.CLOUDSMITH_API_KEY }}
        run: |
          ./docker-wrapper.sh build-run -r suntong/process_hog_watcher -k ${{ secrets.CLOUDSMITH_API_KEY }}
```

### Docker in CI/CD

```bash
docker run --rm \
  -e GITHUB_REPO=suntong/process_hog_watcher \
  -e CLOUDSMITH_API_KEY=$CLOUDSMITH_API_KEY \
  github-to-cloudsmith:latest
```

## Troubleshooting

### No packages found
- Check if the repository has a latest release with .deb, .rpm, or .apk files

### Cloudsmith push failed
- Verify your Cloudsmith API key is valid
- Check that the Cloudsmith repository exists and you have push permissions
- Ensure the repository path is correct

### GitHub API rate limit
- For private repos, use a GitHub token
- Wait for rate limit to reset or increase authentication level

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.