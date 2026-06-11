#!/usr/bin/env bash
# Seismic toolchain environment — sources sforge / ssolc / sanvil from a
# repo-local install at .seismic-toolchain/ (git-ignored).
#
# USAGE
#   From the repo root in any bash/zsh shell:
#       source scripts/seismic-env.sh
#   After sourcing, `sforge`, `ssolc`, and `sanvil` resolve to the repo-local
#   binaries. The export survives until the shell exits.
#
# FIRST-TIME INSTALL
#   1. source scripts/seismic-env.sh
#   2. curl -L -H "Accept: application/vnd.github.v3.raw" \
#        "https://api.github.com/repos/SeismicSystems/seismic-foundry/contents/sfoundryup/install?ref=seismic" | bash
#      The installer writes sfoundryup to $FOUNDRY_DIR/bin/sfoundryup.
#   3. sfoundryup
#      Fetches sforge / ssolc / sanvil into $FOUNDRY_DIR/bin.
#   4. sforge --version && ssolc --version && sanvil --version
#
# NOTES
# - FOUNDRY_DIR is the env var the Seismic installer honors. Pointing it at
#   the repo-local path overrides the default of "$HOME/.seismic".
# - Pre-prepending $FOUNDRY_DIR/bin to PATH causes the installer's rc-edit
#   check to find the bin dir already on PATH and skip mutating ~/.zshenv
#   on most versions of the upstream script. If a future installer revision
#   still appends an export line, remove it from ~/.zshenv by hand — the
#   binaries continue to work via this sourced env.
# - Coexists with stock Foundry: `forge` (stock) and `sforge` (Seismic) live
#   in different bin dirs and have different names — no collisions.

# Resolve repo root from this script's own path (works whether sourced from
# repo root, from a subdir, or from $PATH after `chmod +x`).
__SEISMIC_ENV_SH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
SEISMIC_REPO_ROOT="$(cd "$__SEISMIC_ENV_SH_DIR/.." && pwd)"

export FOUNDRY_DIR="$SEISMIC_REPO_ROOT/.seismic-toolchain"
export FOUNDRY_BIN_DIR="$FOUNDRY_DIR/bin"

# Only prepend if not already present (avoids growing PATH on repeated sources).
case ":$PATH:" in
    *":$FOUNDRY_BIN_DIR:"*) ;;
    *) export PATH="$FOUNDRY_BIN_DIR:$PATH" ;;
esac

# Shell function that pins FOUNDRY_PROFILE=seismic for sforge invocations so
# `evm_version = "mercury"` (required for shielded types) is applied without
# the caller having to remember the flag. `forge` (stock) is untouched and
# continues using the default profile + cancun.
# Override per-call with `FOUNDRY_PROFILE=default sforge ...` if needed.
sforge() {
    FOUNDRY_PROFILE="${FOUNDRY_PROFILE:-seismic}" command sforge "$@"
}

# Surface a one-line confirmation so the user knows the env is active.
if [ -x "$FOUNDRY_BIN_DIR/sforge" ]; then
    echo "seismic-env: ready — $($FOUNDRY_BIN_DIR/sforge --version 2>/dev/null | head -1) (sforge auto-uses FOUNDRY_PROFILE=seismic)"
else
    echo "seismic-env: FOUNDRY_DIR=$FOUNDRY_DIR (binaries not yet installed — run sfoundryup)"
fi

unset __SEISMIC_ENV_SH_DIR
