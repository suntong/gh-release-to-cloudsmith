#!/bin/bash

# Example usage script for github-to-cloudsmith

# This script demonstrates how to use the GitHub to Cloudsmith sync tool

echo "=========================================="
echo "GitHub to Cloudsmith - Usage Examples"
echo "=========================================="
echo

# Example 1: Basic usage with environment variables
echo "Example 1: Basic usage with environment variables"
echo "--------------------------------------------------"
cat << 'EOF'
export GITHUB_REPO=suntong/process_hog_watcher
export CLOUDSMITH_API_KEY=your-cloudsmith-api-key

./github-to-cloudsmith.sh
EOF
echo

# Example 2: Using command-line arguments
echo "Example 2: Using command-line arguments"
echo "--------------------------------------------------"
cat << 'EOF'
./github-to-cloudsmith.sh \
    -r suntong/process_hog_watcher \
    -k your-cloudsmith-api-key
EOF
echo

# Example 3: With custom workspace and download directory
echo "Example 3: With custom workspace and download directory"
echo "--------------------------------------------------"
cat << 'EOF'
./github-to-cloudsmith.sh \
    -r suntong/process_hog_watcher \
    -w myworkspace/myrepo \
    -k your-cloudsmith-api-key \
    -d ./my-downloads
EOF
echo

# Example 4: Selective package types
echo "Example 4: Selective package types"
echo "--------------------------------------------------"
cat << 'EOF'
# Only sync .deb and .rpm files (skip .apk)
./github-to-cloudsmith.sh \
    -r suntong/process_hog_watcher \
    -k your-cloudsmith-api-key \
    --skip-apk

# Note: Android APK files (.apk) are automatically skipped
# Only Alpine Linux packages (.apk with gzip/zstd/tar MIME type) are pushed

# Only sync Alpine packages (skip .deb and .rpm)
./github-to-cloudsmith.sh \
    -r suntong/process_hog_watcher \
    -k your-cloudsmith-api-key \
    --skip-deb \
    --skip-rpm
EOF
echo

# Example 5: Docker usage
echo "Example 5: Docker usage"
echo "--------------------------------------------------"
cat << 'EOF'
# Build the Docker image
./docker-wrapper.sh build

# Run the sync
./docker-wrapper.sh run \
    -r suntong/process_hog_watcher \
    -k your-cloudsmith-api-key

# Or build and run in one step
./docker-wrapper.sh build-run \
    -r suntong/process_hog_watcher \
    -k your-cloudsmith-api-key
EOF
echo

# Example 6: Docker with custom image name
echo "Example 6: Docker with custom image name"
echo "--------------------------------------------------"
cat << 'EOF'
./docker-wrapper.sh build-run \
    -n my-custom-image \
    -g v1.0.0 \
    -r suntong/process_hog_watcher \
    -k your-cloudsmith-api-key
EOF
echo

# Example 7: Docker with environment variables
echo "Example 7: Docker with environment variables"
echo "--------------------------------------------------"
cat << 'EOF'
export GITHUB_REPO=suntong/process_hog_watcher
export CLOUDSMITH_API_KEY=your-cloudsmith-api-key

./docker-wrapper.sh run
EOF
echo

# Example 8: Direct Docker run command
echo "Example 8: Direct Docker run command"
echo "--------------------------------------------------"
cat << 'EOF'
docker run --rm \
  -e GITHUB_REPO=suntong/process_hog_watcher \
  -e CLOUDSMITH_API_KEY=your-cloudsmith-api-key \
  github-to-cloudsmith:latest
EOF
echo

# Example 9: With private GitHub repository
echo "Example 9: With private GitHub repository"
echo "--------------------------------------------------"
cat << 'EOF'
export GITHUB_REPO=your-username/your-private-repo
export GITHUB_TOKEN=your-github-token
export CLOUDSMITH_API_KEY=your-cloudsmith-api-key

./github-to-cloudsmith.sh
EOF
echo

# Example 10: Integration with cron (scheduled sync)
echo "Example 10: Integration with cron (scheduled sync)"
echo "--------------------------------------------------"
cat << 'EOF'
# Add to crontab for daily sync at midnight
# 0 0 * * * cd /path/to/github-to-cloudsmith && ./github-to-cloudsmith.sh -r suntong/process_hog_watcher -k your-cloudsmith-api-key > /var/log/cloudsmith-sync.log 2>&1
EOF
echo

echo "=========================================="
echo "For more information, see README.md"
echo "=========================================="
