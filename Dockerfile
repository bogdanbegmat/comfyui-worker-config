# 1. Start from a SPECIFIC version of the official worker to ensure stability.
FROM runpod/worker-comfyui:5.3.0-base

# 2. Copy the pre-generated dependency list into the image.
COPY constraints.txt /opt/constraints.txt

# 3. Install the dependencies. This happens only ONCE during the image build.
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-deps -r /opt/constraints.txt

# 4. Copy the lean startup script and make it executable.
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh

# 5. Tell the RunPod environment to use our script on boot.
ENV STARTUP_SCRIPT="/usr/local/bin/startup.sh"
