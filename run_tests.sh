#!/usr/bin/env bash

set -e -x

# Install axlearn along with development dependencies. This pulls in
# JAX, seqio, timm and other packages required by the tests.
pip install -e '.[dev]'

# Some environments may not correctly install optional extras, so we
# explicitly ensure a few core packages are available.
pip install --no-deps jax==0.5.3 jaxlib==0.5.3 seqio==0.0.18 toml pika pre-commit pytest pytest-xdist

# Ensure core test dependencies are available. Some environments may
# not install optional extras correctly, so we install them explicitly.
pip install jax==0.5.3 jaxlib==0.5.3 seqio==0.0.18 toml pika pre-commit pytest pytest-xdist

# Log installed versions
echo "PIP FREEZE:"
pip freeze

exit_if_error() {
  local exit_code=$1
  shift
  printf 'ERROR: %s\n' "$@" >&2
  exit "$exit_code"
}

download_assets() {
  set -e -x
  mkdir -p axlearn/data/tokenizers/sentencepiece
  mkdir -p axlearn/data/tokenizers/bpe
  curl https://huggingface.co/t5-base/resolve/main/spiece.model -o axlearn/data/tokenizers/sentencepiece/t5-base
  curl https://huggingface.co/FacebookAI/roberta-base/raw/main/merges.txt -o axlearn/data/tokenizers/bpe/roberta-base-merges.txt
  curl https://huggingface.co/FacebookAI/roberta-base/raw/main/vocab.json -o axlearn/data/tokenizers/bpe/roberta-base-vocab.json
}

precommit_checks() {
  set -e -x
  pre-commit install
  pre-commit run --all-files || exit_if_error $? "pre-commit failed."
  # Run pytype separately to utilize all cpus and for better output.
  pytype -j auto . || exit_if_error $? "pytype failed."
}

# Collect all background PIDs explicitly.
TEST_PIDS=()

download_assets

if [[ "${1:-x}" = "--skip-pre-commit" ]] ; then
  SKIP_PRECOMMIT=true
  shift
fi

# Skip pre-commit on parallel CI because it is run as a separate job.
if [[ "${SKIP_PRECOMMIT:-false}" = "false" ]] ; then
  precommit_checks &
  TEST_PIDS[$!]=1
fi

UNQUOTED_PYTEST_FILES=$(echo $1 |  tr -d "'")
pytest --durations=100 -v -n auto \
  -m "not (gs_login or tpu or high_cpu or fp64 or for_8_devices)" ${UNQUOTED_PYTEST_FILES} \
  --dist worksteal &
TEST_PIDS[$!]=1

JAX_ENABLE_X64=1 pytest --durations=100 -v -n auto -v -m "fp64" --dist worksteal &
TEST_PIDS[$!]=1

XLA_FLAGS="--xla_force_host_platform_device_count=8" pytest --durations=100 -v \
  -n auto -v -m "for_8_devices" --dist worksteal &
TEST_PIDS[$!]=1

# Use Bash 5.1's new wait -p feature to quit immediately if any subprocess fails to make error
# finding a bit easier.
while [ ${#TEST_PIDS[@]} -ne 0 ]; do
  wait -n -p PID ${!TEST_PIDS[@]} || exit_if_error $? "Test failed."
  unset TEST_PIDS[$PID]
done
