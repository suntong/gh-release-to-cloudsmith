# Dockerfile for GitHub to Cloudsmith Package Sync
# Based on Cloudsmith CLI Docker image

FROM cloudsmith/cloudsmith-cli:latest

#LABEL maintainer="your-email@example.com"
LABEL description="Copy GitHub release packages to Cloudsmith"

# Set working directory
WORKDIR /app

# Install additional tools
RUN apk update && \
    apk add --no-cache \
    curl \
    file jq \
    bash \
    && rm -rf /var/cache/apk/*

# Copy the sync script
COPY github-to-cloudsmith.sh /app/github-to-cloudsmith.sh

# Make the script executable
RUN chmod +x /app/github-to-cloudsmith.sh

# Create a directory for downloads
RUN mkdir -p /tmp/cloudsmith-sync

# Set the default command
ENTRYPOINT ["/app/github-to-cloudsmith.sh"]
