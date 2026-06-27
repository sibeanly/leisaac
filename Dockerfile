FROM my-isaac-lab:v1.0

LABEL maintainer="LeIsaac Builder" \
      description="LeIsaac (LeRobot + IsaacLab) running on IsaacSim 5.1 + IsaacLab v2.3.0" \
      version="0.4.0"

# ============================================================
# Proxy: passed at build time. Use --network=host so that
# 127.0.0.1 resolves to the host where the proxy runs.
# Docker daemon may also inject its own proxy env vars,
# so we unset them explicitly before every pip invocation.
# ============================================================
ARG http_proxy
ARG https_proxy
ARG no_proxy

# ============================================================
# Configure pip to use Tsinghua mirror (no proxy needed for pip)
# ============================================================
RUN unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY && \
    /isaac-sim/python.sh -m pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple && \
    /isaac-sim/python.sh -m pip config set global.trusted-host pypi.tuna.tsinghua.edu.cn

# ============================================================
# Copy LeIsaac source code
# ============================================================
COPY leisaac /workspace/leisaac

# ============================================================
# Upgrade pip (vendored packaging in old pip breaks metadata-gen)
# ============================================================
RUN unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY && \
    /isaac-sim/python.sh -m pip install --no-cache-dir --upgrade pip

# ============================================================
# Install LeIsaac core package
# ============================================================
RUN unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY && \
    /isaac-sim/python.sh -m pip install --no-cache-dir \
        -e /workspace/leisaac/source/leisaac

# ============================================================
# Install LeRobot data support
# ============================================================
RUN unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY && \
    /isaac-sim/python.sh -m pip install --no-cache-dir \
        -e "/workspace/leisaac/source/leisaac[lerobot]"

# ============================================================
# Install GR00T N1.5/N1.6 policy inference support
# ============================================================
RUN unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY && \
    /isaac-sim/python.sh -m pip install --no-cache-dir \
        -e "/workspace/leisaac/source/leisaac[gr00t]"

# ============================================================
# Install remote teleoperation support (ZMQ)
# ============================================================
RUN unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY && \
    /isaac-sim/python.sh -m pip install --no-cache-dir --no-build-isolation \
        -e "/workspace/leisaac/source/leisaac[remote]"

# ============================================================
# Install lerobot-async (gRPC for async LeRobot)
# ============================================================
RUN unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY && \
    /isaac-sim/python.sh -m pip install --no-cache-dir --no-build-isolation \
        -e "/workspace/leisaac/source/leisaac[lerobot-async]"

# ============================================================
# Pin numpy to v1 (IsaacLab requires numpy<2; lerobot upgrades
# it to v2 which breaks IsaacLab).
#
# Fix torch vendored packaging symlink: packaging upgrade
# removed the target at
#   omni.isaac.core_archive/pip_prebundle/packaging/
# which torch._vendor.packaging._structures.py symlinked to.
# Replace the broken symlink with a direct copy.
# ============================================================
RUN unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY && \
    /isaac-sim/python.sh -m pip install --no-cache-dir \
        numpy==1.26.0 && \
    TORCH_VENDOR=/isaac-sim/exts/omni.isaac.ml_archive/pip_prebundle/torch/_vendor/packaging && \
    if [ -L "$TORCH_VENDOR/_structures.py" ] && [ ! -f "$(readlink -f "$TORCH_VENDOR/_structures.py" 2>/dev/null)" ]; then \
        rm -f "$TORCH_VENDOR/_structures.py" && \
        cp /isaac-sim/kit/python/lib/python3.11/site-packages/packaging/_structures.py \
           "$TORCH_VENDOR/_structures.py" && \
        rm -rf "$TORCH_VENDOR/__pycache__"; \
    fi

# ============================================================
# Set working directory to LeIsaac project root
# ============================================================
WORKDIR /workspace/leisaac
CMD ["/bin/bash"]
