# 1. Start from a SPECIFIC version of the official worker to ensure stability.
FROM runpod/worker-comfyui:5.3.0-base

# 2. Switch to ROOT user for all installation tasks.
USER root

# 3. Install git, which we need for cloning.
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# 4. Set the working directory for custom nodes and copy our repository list.
WORKDIR /comfyui/custom_nodes
COPY git_clones.txt /tmp/git_clones.txt

# 5. Clone all repositories from our list as the root user.
RUN while IFS=',' read -r repo_url commit_hash; do \
      repo_url=$(echo "$repo_url" | xargs); \
      commit_hash=$(echo "$commit_hash" | xargs); \
      git clone "$repo_url"; \
      if [ -n "$commit_hash" ]; then \
        echo "Checking out commit $commit_hash for $repo_url"; \
        (cd "$(basename "$repo_url" .git)" && git checkout "$commit_hash"); \
      fi; \
    done < /tmp/git_clones.txt

# 6. Copy our pre-vetted dependency files into the image.
COPY constraints.txt /opt/constraints.txt
COPY git-requirements.txt /opt/git-requirements.txt

# 7. Install all dependencies as ROOT to ensure permissions are correct.
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-deps --no-build-isolation -r /opt/git-requirements.txt && \
    pip install -r /opt/constraints.txt --use-feature=fast-deps

# 8. Change ownership of the entire comfyui directory back to the default user.
#    This is a critical security and operational best practice.
RUN chown -R 1000:1000 /comfyui

# 9. Switch back to the standard, non-root user for the final runtime environment.
USER 1000

# 10. Reset the working directory and set up the final startup script.
WORKDIR /comfyui
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh
ENV STARTUP_SCRIPT="/usr/local/bin/startup.sh"