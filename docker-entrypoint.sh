#!/bin/bash
# SPDX-License-Identifier: (GPL-2.0+ OR MIT)
# Simplified entrypoint for Cloud Build - based on Variscite pattern

# Verify container user was set
if [ -z "${USER}" ]; then
  echo "ERROR: USER not set in Dockerfile"
  exit 1
fi

# For Cloud Build, we don't need UID/GID matching since we're not mounting host dirs
# Just ensure workspace ownership is correct
if [ -d "/workspace" ]; then
    chown -R ${USER}:${USER} /workspace 2>/dev/null || true
fi

# Fix .netrc permissions if it exists
if [ -f "/builder/home/.netrc" ]; then
    chmod 600 /builder/home/.netrc 2>/dev/null || true
    chown ${USER}:${USER} /builder/home/.netrc 2>/dev/null || true
fi

# Set working directory in bashrc
echo "cd /workspace" > /home/${USER}/.bashrc

# If a command was passed, execute it as the user
# Otherwise, start a login shell as the user
if [ -n "$1" ]; then
    exec su - "${USER}" -c "$*"
else
    exec su - "${USER}"
fi
