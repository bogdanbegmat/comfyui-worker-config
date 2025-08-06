# 1. Start from a SPECIFIC version of the official worker to ensure stability.
FROM runpod/worker-comfyui:5.3.0-base

# 2. Install git, which we need for cloning.
USER root
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# 3. Set the working directory for custom nodes and copy our repository list.
WORKDIR /comfyui/custom_nodes
COPY git_clones.txt /tmp/git_clones.txt

# 4. Clone all repositories from our list as the root user.
RUN while IFS=',' read -r repo_url commit_hash; do \
      repo_url=$(echo "$repo_url" | xargs); \
      commit_hash=$(echo "$commit_hash" | xargs); \
      git clone "$repo_url"; \
      if [ -n "$commit_hash" ]; then \
        echo "Checking out commit $commit_hash for $repo_url"; \
        (cd "$(basename "$repo_url" .git)" && git checkout "$commit_hash"); \
      fi; \
    done < /tmp/git_clones.txt

# 5. Change ownership of all cloned files back to the default user.
RUN chown -R 1000:1000 /comfyui/custom_nodes

# 6. Switch back to the standard, non-root user.
USER 1000

# 7. Copy our OWN pre-vetted dependency files into the image.
COPY constraints.txt /opt/constraints.txt
COPY git-requirements.txt /opt/git-requirements.txt

# 8. Install dependencies using our controlled files, not the ones from the repos.
RUN --mount=type=cache,target=/root/.cache/pip \
    # Install git-based packages first from our clean git-requirements.txt
    pip install --no-deps --no-build-isolation -r /opt/git-requirements.txt && \
    # Install standard packages from our clean constraints.txt
    pip install -r /opt/constraints.txt --use-feature=fast-deps

# 9. Reset the working directory and set up the final startup script.
WORKDIR /comfyui
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh
ENV STARTUP_SCRIPT="/usr/local/bin/startup.sh"