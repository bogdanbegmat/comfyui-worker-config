# 1. Start from the official base image.
FROM runpod/worker-comfyui:5.3.0-base

# 2. Environment tweaks – keep installations quiet & skip pip version banner.
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# 3. Switch to ROOT user for all installation tasks.
USER root

# 4. Install git.
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# 5. Set the working directory for custom nodes and copy our repository list.
WORKDIR /comfyui/custom_nodes
COPY git_clones.txt /tmp/git_clones.txt

# 6. Clone all repositories from our list.
RUN while IFS=',' read -r repo_url commit_hash; do \
      repo_url=$(echo "$repo_url" | xargs); \
      commit_hash=$(echo "$commit_hash" | xargs); \
      git clone "$repo_url"; \
      if [ -n "$commit_hash" ]; then \
        echo "Checking out commit $commit_hash for $repo_url"; \
        (cd "$(basename "$repo_url" .git)" && git checkout "$commit_hash"); \
      fi; \
    done < /tmp/git_clones.txt

# 7. Copy our pre‑vetted dependency files.
COPY constraints.txt /opt/constraints.txt
COPY git-requirements.txt /opt/git-requirements.txt

# 8. Install python dependencies.
#    * Drop lines that would bloat or break the build.
#    * Mount /root/.cache/pip so wheels are cached between builds but not baked into the image.
RUN --mount=type=cache,target=/root/.cache/pip \
    sed -i '/^was-node-suite-comfyui$/d' /opt/constraints.txt && \
    sed -i '/^opencv-python$/d;/^opencv-contrib-python$/d' /opt/constraints.txt && \
    pip install --no-deps --no-build-isolation -r /opt/git-requirements.txt && \
    pip install -r /opt/constraints.txt --use-feature=fast-deps && \
    rm -rf /root/.cache/pip

# 9. Copy the startup script and set its permissions.
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh

# 10. Change ownership of the custom nodes back to the default user.
RUN chown -R 1000:1000 /comfyui/custom_nodes

# 11. Switch back to the standard, non‑root user for the final runtime environment.
USER 1000

# 12. Final setup.
WORKDIR /comfyui
ENV STARTUP_SCRIPT="/usr/local/bin/startup.sh"