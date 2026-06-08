#!/bin/bash

# Docker wrapper script for github-to-cloudsmith

# Default values
DEFAULT_CLOUDSMITH_REPO="${CLOUDSMITH_REPO:-suntong/repo}"
DEFAULT_GITHUB_REPO="${GITHUB_REPO:-}"
IMAGE_NAME="${IMAGE_NAME:-github-to-cloudsmith}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

# Parse arguments
GITHUB_REPO="$DEFAULT_GITHUB_REPO"
CLOUDSMITH_REPO="$DEFAULT_CLOUDSMITH_REPO"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
CLOUDSMITH_API_KEY="${CLOUDSMITH_API_KEY:-}"
BUILD_IMAGE=false
RUN_CONTAINER=false

print_usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

COMMANDS:
    build                   Build the Docker image
    run                     Run the Docker container
    build-run               Build and run in one step

OPTIONS for 'run' and 'build-run':
    -r, --repo REPO         GitHub repository in format "owner/repo" (required)
    -w, --workspace REPO    Cloudsmith workspace/repo (default: ${DEFAULT_CLOUDSMITH_REPO})
    -t, --token TOKEN       GitHub API token (optional for public repos)
    -k, --api-key KEY       Cloudsmith API key (required)
    --skip-deb              Skip .deb files
    --skip-rpm              Skip .rpm files
    --skip-apk              Skip .apk files

OPTIONS for 'build':
    -n, --name NAME         Docker image name (default: ${IMAGE_NAME})
    -g, --tag TAG           Docker image tag (default: ${IMAGE_TAG})

ENVIRONMENT VARIABLES:
    GITHUB_REPO             GitHub repository in format "owner/repo" (required)
    CLOUDSMITH_REPO         Default Cloudsmith workspace/repo
    CLOUDSMITH_API_KEY      Default Cloudsmith API key
    GITHUB_TOKEN            Default GitHub API token
    IMAGE_NAME              Default Docker image name
    IMAGE_TAG               Default Docker image tag

EXAMPLES:
    # Build the Docker image
    $0 build

    # Run the container
    $0 run -r suntong/process_hog_watcher -k YOUR_CLOUDSMITH_API_KEY

    # Build and run in one step
    $0 build-run -r suntong/process_hog_watcher -k YOUR_CLOUDSMITH_API_KEY

    # Using environment variables
    export GITHUB_REPO=suntong/process_hog_watcher
    export CLOUDSMITH_API_KEY=YOUR_CLOUDSMITH_API_KEY
    $0 run

EOF
}

# Parse command line
if [[ $# -eq 0 ]]; then
    print_usage
    exit 0
fi

COMMAND="$1"
shift

case "$COMMAND" in
    build)
        BUILD_IMAGE=true
        ;;
    run)
        RUN_CONTAINER=true
        ;;
    build-run)
        BUILD_IMAGE=true
        RUN_CONTAINER=true
        ;;
    -h|--help|help)
        print_usage
        exit 0
        ;;
    *)
        echo "Error: Unknown command '$COMMAND'"
        echo "Use '$0 --help' for usage information."
        exit 1
        ;;
esac

# Parse additional arguments
DOCKER_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
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
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -g|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        --skip-deb|--skip-rpm|--skip-apk)
            DOCKER_ARGS+=("$1")
            shift
            ;;
        *)
            echo "Error: Unknown option $1"
            print_usage
            exit 1
            ;;
    esac
done

# Build Docker image
if [[ "$BUILD_IMAGE" == "true" ]]; then
    echo "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
    docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .
    echo "✓ Docker image built successfully"
fi

# Run Docker container
if [[ "$RUN_CONTAINER" == "true" ]]; then
    # Validate required parameters
    if [[ -z "$GITHUB_REPO" ]]; then
        echo "Error: GitHub repository is required. Use -r option or set GITHUB_REPO environment variable."
        echo "Format: owner/repo (e.g., suntong/process_hog_watcher)"
        exit 1
    fi

    if [[ -z "$CLOUDSMITH_API_KEY" ]]; then
        echo "Error: Cloudsmith API key is required. Use -k option or set CLOUDSMITH_API_KEY environment variable."
        exit 1
    fi

    echo "Running Docker container..."
    echo "GitHub Repository: ${GITHUB_REPO}"
    echo "Cloudsmith Repository: ${CLOUDSMITH_REPO}"
    echo

    docker run --rm \
        -e GITHUB_REPO="${GITHUB_REPO}" \
        -e CLOUDSMITH_REPO="${CLOUDSMITH_REPO}" \
        -e GITHUB_TOKEN="${GITHUB_TOKEN}" \
        -e CLOUDSMITH_API_KEY="${CLOUDSMITH_API_KEY}" \
        "${IMAGE_NAME}:${IMAGE_TAG}" \
        "${DOCKER_ARGS[@]}"
fi