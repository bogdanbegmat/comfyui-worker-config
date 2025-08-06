# 1. Start from a SPECIFIC version of the official worker to ensure stability.
FROM runpod/worker-comfyui:5.3.0-base

# 2. Install git, which we need for cloning.
USER root
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# 3. Set the working directory to where custom nodes should live.
WORKDIR /comfyui/custom_nodes

# 4. Copy our list of repositories into a temporary location.
COPY git_clones.txt /tmp/git_clones.txt

# 5. Read the file and clone each repository.
#    This is now run as ROOT to ensure we have permission to create directories.
RUN while IFS=',' read -r repo_url commit_hash; do \
      repo_url=$(echo "$repo_url" | xargs); \
      commit_hash=$(echo "$commit_hash" | xargs); \
      git clone "$repo_url"; \
      if [ -n "$commit_hash" ]; then \
        echo "Checking out commit $commit_hash for $repo_url"; \
        (cd "$(basename "$repo_url" .git)" && git checkout "$commit_hash"); \
      fi; \
    done < /tmp/git_clones.txt

# 6. Change ownership of all cloned files back to the default user.
RUN chown -R 1000:1000 /comfyui/custom_nodes

# 7. Switch back to the standard, non-root user for all subsequent commands.
USER 1000

# 8. Install all Python dependencies found in the cloned repos.
#    IMPORTANT: We explicitly use "/bin/bash -c" to ensure the correct shell is used.
RUN --mount=type=cache,target=/root/.cache/pip \
    bash -c "pip install -r <(find . -name 'requirements.txt' -exec cat {} + | sort -u) --use-feature=fast-deps"

# 9. Reset the working directory and set up the final startup script.
WORKDIR /comfyui
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh
ENV STARTUP_SCRIPT="/usr/local/bin/startup.sh"