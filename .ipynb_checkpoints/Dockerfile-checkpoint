# ==============================================================================
# Stage 1: The "Builder"
# This stage does all the heavy lifting: cloning and installing.
# ==============================================================================
FROM runpod/worker-comfyui:5.3.0-base AS builder

# Switch to ROOT for all installation tasks.
USER root

# Install git.
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Copy our clean, pre-vetted dependency lists.
COPY constraints.txt /opt/constraints.txt
COPY git-requirements.txt /opt/git-requirements.txt

# Install all Python packages from our lists into the builder's venv.
# This creates a fully populated Python environment that we can copy later.
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-deps --no-build-isolation -r /opt/git-requirements.txt && \
    pip install -r /opt/constraints.txt --use-feature=fast-deps

# Set the working directory for custom nodes and copy our repository list.
WORKDIR /comfyui/custom_nodes
COPY git_clones.txt /tmp/git_clones.txt

# Clone all custom node repositories.
RUN while IFS=',' read -r repo_url commit_hash; do \
      repo_url=$(echo "$repo_url" | xargs); \
      commit_hash=$(echo "$commit_hash" | xargs); \
      git clone "$repo_url"; \
      if [ -n "$commit_hash" ]; then \
        echo "Checking out commit $commit_hash for $repo_url"; \
        (cd "$(basename "$repo_url" .git)" && git checkout "$commit_hash"); \
      fi; \
    done < /tmp/git_clones.txt


# ==============================================================================
# Stage 2: The "Final" Image
# This is the lean, clean image that will actually be deployed.
# ==============================================================================
FROM runpod/worker-comfyui:5.3.0-base

# As before, switch to root to perform system-level tasks.
USER root

# Copy the fully installed Python virtual environment from the builder stage.
COPY --from=builder /opt/venv /opt/venv

# Copy the fully cloned custom nodes directory from the builder stage.
COPY --from=builder /comfyui/custom_nodes /comfyui/custom_nodes

# Copy the startup script and set its permissions.
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh

# Change ownership of all our added files to the default user.
RUN chown -R 1000:1000 /comfyui /opt/venv

# Switch back to the standard, non-root user for the runtime environment.
USER 1000

# Final setup: Reset the working directory and point to the startup script.
WORKDIR /comfyui
ENV STARTUP_SCRIPT="/usr/local/bin/startup.sh"