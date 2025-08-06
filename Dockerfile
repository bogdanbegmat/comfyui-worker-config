# 1. Start from a SPECIFIC version of the official worker to ensure stability.
FROM runpod/worker-comfyui:5.3.0-base

# 2. Copy BOTH requirements files into the image.
COPY constraints.txt /opt/constraints.txt
COPY git-requirements.txt /opt/git-requirements.txt

# 3. Install packages in two steps.
RUN --mount=type=cache,target=/root/.cache/pip \
    # Step A: Install standard packages from PyPI.
    pip install --no-deps -r /opt/constraints.txt && \
    # Step B: Install git packages, preventing them from re-downloading torch.
    pip install --no-deps --no-build-isolation -r /opt/git-requirements.txt

# 4. Copy the lean startup script and make it executable.
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh

# 5. Tell the RunPod environment to use our script on boot.
ENV STARTUP_SCRIPT="/usr/local/bin/startup.sh"
