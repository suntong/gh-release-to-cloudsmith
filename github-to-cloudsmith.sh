#!/bin/bash

# GitHub to Cloudsmith Package Sync Script
# This script downloads the latest release packages from a GitHub repository
# and pushes them to Cloudsmith

set -euo pipefail

# Default values (from suntong/process_hog_watcher workflow)
DEFAULT_CLOUDSMITH_REPO="${CLOUDSMITH_REPO:-suntong/repo}"
DEFAULT_GITHUB_REPO="${GITHUB_REPO:-}"

# Help message
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Download latest release packages from GitHub and push to Cloudsmith.

OPTIONS:
    -h, --help              Show this help message
    -r, --repo REPO         GitHub repository in format "owner/repo" (required)
    -w, --workspace REPO    Cloudsmith workspace/repo (default: ${DEFAULT_CLOUDSMITH_REPO})
    -t, --token TOKEN       GitHub API token (optional for public repos)
    -k, --api-key KEY       Cloudsmith API key (required)
    -d, --download-dir DIR  Directory to download files (default: /tmp/cloudsmith-sync)
    --skip-deb              Skip .deb files
    --skip-rpm              Skip .rpm files
    --skip-apk              Skip .apk files

ENVIRONMENT VARIABLES:
    GITHUB_REPO             GitHub repository in format "owner/repo" (required)
    CLOUDSMITH_REPO         Default Cloudsmith workspace/repo
    CLOUDSMITH_API_KEY      Default Cloudsmith API key
    GITHUB_TOKEN            Default GitHub API token

EXAMPLES:
    # Basic usage with all parameters
    $0 -r suntong/process_hog_watcher -k YOUR_CLOUDSMITH_API_KEY

    # Using environment variables
    export GITHUB_REPO=suntong/process_hog_watcher
    export CLOUDSMITH_API_KEY=YOUR_CLOUDSMITH_API_KEY
    $0

    # With custom workspace and download directory
    $0 -r suntong/process_hog_watcher -w myworkspace/myrepo -k YOUR_KEY -d ./downloads

EOF
    exit 0
}

# Parse command line arguments
GITHUB_REPO="$DEFAULT_GITHUB_REPO"
CLOUDSMITH_REPO="${DEFAULT_CLOUDSMITH_REPO}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
CLOUDSMITH_API_KEY="${CLOUDSMITH_API_KEY:-}"
DOWNLOAD_DIR="/tmp/cloudsmith-sync"
SKIP_DEB=false
SKIP_RPM=false
SKIP_APK=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -r|--repo)
            GITHUB_REPO="$2"
            shift 2
            ;;
        -w|--workspace)
            CLOUDSMITH_REPO="$2"
            shift 2
            ;;
        -t|--token)
            GITHUB_TOKEN="$2"
            shift 2
            ;;
        -k|--api-key)
            CLOUDSMITH_API_KEY="$2"
            shift 2
            ;;
        -d|--download-dir)
            DOWNLOAD_DIR="$2"
            shift 2
            ;;
        --skip-deb)
            SKIP_DEB=true
            shift
            ;;
        --skip-rpm)
            SKIP_RPM=true
            shift
            ;;
        --skip-apk)
            SKIP_APK=true
            shift
            ;;
        *)
            echo "Error: Unknown option $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [[ -z "$GITHUB_REPO" ]]; then
    echo "Error: GitHub repository is required. Use -r option or set GITHUB_REPO environment variable."
    echo "Format: owner/repo (e.g., suntong/process_hog_watcher)"
    exit 1
fi

# Parse owner and repo from GITHUB_REPO (support "owner/repo" format)
if [[ "$GITHUB_REPO" == */* ]]; then
    GITHUB_OWNER="${GITHUB_REPO%%/*}"
    REPO_NAME="${GITHUB_REPO##*/}"
else
    echo "Error: GitHub repository must be in 'owner/repo' format (e.g., suntong/process_hog_watcher)"
    exit 1
fi

if [[ -z "$CLOUDSMITH_API_KEY" ]]; then
    echo "Error: Cloudsmith API key is required. Use -k option or set CLOUDSMITH_API_KEY environment variable."
    exit 1
fi

# Create download directory
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

echo "=========================================="
echo "GitHub to Cloudsmith Package Sync"
echo "=========================================="
echo "GitHub Repository: ${GITHUB_OWNER}/${REPO_NAME}"
echo "Cloudsmith Repository: ${CLOUDSMITH_REPO}"
echo "Download Directory: ${DOWNLOAD_DIR}"
echo "=========================================="
echo

# Build GitHub API request URL
GITHUB_API_URL="https://api.github.com/repos/${GITHUB_OWNER}/${REPO_NAME}/releases/latest"

# Fetch latest release information
echo "Fetching latest release from GitHub..."
if [[ -n "$GITHUB_TOKEN" ]]; then
    RELEASE_DATA=$(curl -s -L \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        -H "X-GitHub-Api-Version: 2026-03-10" \
        "${GITHUB_API_URL}")
else
    RELEASE_DATA=$(curl -s -L \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2026-03-10" \
        "${GITHUB_API_URL}")
fi

# Check if release data is valid
if ! echo "$RELEASE_DATA" | jq -e '.tag_name' > /dev/null 2>&1; then
    echo "Error: Failed to fetch release data or no release found."
    echo "Response: $RELEASE_DATA"
    exit 1
fi

# Extract release information
TAG_NAME=$(echo "$RELEASE_DATA" | jq -r '.tag_name')
PUBLISHED_AT=$(echo "$RELEASE_DATA" | jq -r '.published_at')

echo "Latest Release: ${TAG_NAME}"
echo "Published At: ${PUBLISHED_AT}"
echo

# Extract asset download URLs
ASSET_URLS=$(echo "$RELEASE_DATA" | jq -r '.assets[] | select(.name | endswith(".deb") or endswith(".rpm") or endswith(".apk")) | .name + "|" + .browser_download_url + "|" + (.size | tostring)')

if [[ -z "$ASSET_URLS" ]]; then
    echo "No .deb, .rpm, or .apk files found in the latest release."
    exit 0
fi

# Download and push packages
echo "Found packages:"
echo "$ASSET_URLS" | while IFS='|' read -r filename url size; do
    extension="${filename##*.}"
    echo "  - ${filename} (${size} bytes)"
done
echo

# Set Cloudsmith API key
export CLOUDSMITH_API_KEY

# Download and push each package
echo "Processing packages..."
echo "$ASSET_URLS" | while IFS='|' read -r filename url size; do
    extension="${filename##*.}"

    # Skip based on flags
    case "$extension" in
        deb)
            if [[ "$SKIP_DEB" == "true" ]]; then
                echo "Skipping .deb file: ${filename}"
                continue
            fi
            ;;
        rpm)
            if [[ "$SKIP_RPM" == "true" ]]; then
                echo "Skipping .rpm file: ${filename}"
                continue
            fi
            ;;
        apk)
            if [[ "$SKIP_APK" == "true" ]]; then
                echo "Skipping .apk file: ${filename}"
                continue
            fi
            ;;
        *)
            echo "Skipping unknown file type: ${filename}"
            continue
            ;;
    esac

    echo "--------------------------------------------------"
    echo "Processing: ${filename}"
    echo "--------------------------------------------------"

    # Download the file with verbose error output
    echo "Downloading from: ${url}"
    if ! curl -L --fail -w "\nHTTP Status: %{http_code}\n" -o "${filename}" "${url}" 2>&1 | head -20; then
        echo "Error: Failed to download ${filename}"
        continue
    fi

    # Verify file was downloaded
    if [[ ! -f "${filename}" ]]; then
        echo "Error: Downloaded file not found: ${filename}"
        continue
    fi

    downloaded_size=$(stat -c%s "${filename}" 2>/dev/null || stat -f%z "${filename}" 2>/dev/null)
    echo "Downloaded size: ${downloaded_size} bytes"

    # Check if file is empty
    if [[ "$downloaded_size" -eq 0 ]]; then
        echo "Error: Downloaded file is empty: ${filename}"
        rm -f "${filename}"
        continue
    fi

    # For .apk files, detect if it's Alpine package or Android APK
    if [[ "$extension" == "apk" ]]; then
        mime_type=$(file --mime-type "${filename}" | cut -d: -f2 | xargs)
        echo "MIME type: ${mime_type}"

        # Alpine packages: application/gzip, application/zstd, application/x-tar
        # Android APK: application/vnd.android.package-archive, application/zip
        if [[ "$mime_type" == "application/vnd.android.package-archive" ]] || [[ "$mime_type" == "application/zip" ]]; then
            echo "Skipping Android APK file: ${filename} (MIME: ${mime_type})"
            rm -f "${filename}"
            continue
        fi

        if [[ "$mime_type" != "application/gzip" ]] && [[ "$mime_type" != "application/zstd" ]] && [[ "$mime_type" != "application/x-tar" ]]; then
            echo "Warning: Unknown .apk file type: ${mime_type}, skipping: ${filename}"
            rm -f "${filename}"
            continue
        fi
    fi

    # Determine Cloudsmith repository path based on file type
    case "$extension" in
        apk)
            CLOUDSMITH_PATH="${CLOUDSMITH_REPO}/alpine/any-version"
            push_format="alpine"
            ;;
        deb|rpm)
            CLOUDSMITH_PATH="${CLOUDSMITH_REPO}/any-distro/any-version"
            push_format="$extension"
            ;;
        *)
            echo "Unknown file type: ${extension}, skipping"
            rm -f "${filename}"
            continue
            ;;
    esac

    # Push to Cloudsmith
    echo "Pushing to Cloudsmith: ${CLOUDSMITH_PATH} (format: ${push_format})"
    if cloudsmith push "${push_format}" "${CLOUDSMITH_PATH}" "${filename}"; then
        echo "✓ Successfully pushed ${filename}"
    else
        echo "✗ Failed to push ${filename}"
    fi

    # Clean up downloaded file
    rm -f "${filename}"
    echo
done

echo "=========================================="
echo "Sync completed!"
echo "=========================================="