#!/bin/bash
# Dependency checker for the efficiency-game benchmark suite
# Usage:
#   ./scripts/check_dependencies.sh           # lists missing toolchains
#   ./scripts/check_dependencies.sh --install # attempts Homebrew installs for supported tools

set -euo pipefail

AUTO_INSTALL=false
if [[ "${1:-}" == "--install" ]]; then
  AUTO_INSTALL=true
fi

if $AUTO_INSTALL && ! command -v brew >/dev/null 2>&1; then
  echo "Error: Homebrew not found. Install it first from https://brew.sh/" >&2
  exit 1
fi

BREW_AVAILABLE=false
if command -v brew >/dev/null 2>&1; then
  BREW_AVAILABLE=true
fi

missing_cmds=()
missing_installs=()
missing_descs=()

add_missing() {
  local cmd="$1"
  local install="$2"
  local desc="$3"
  missing_cmds+=("$cmd")
  missing_installs+=("$install")
  missing_descs+=("$desc")
}

while IFS='|' read -r cmd install desc; do
  [[ -z "$cmd" ]] && continue
  if command -v "$cmd" >/dev/null 2>&1; then
    continue
  fi
  add_missing "$cmd" "$install" "$desc"
done <<'EOF'
clang|xcode-select --install|Apple Command Line Tools (provides clang/clang++)
clang++|xcode-select --install|Apple Command Line Tools (provides clang++)
python3|brew install python@3.11|Python 3 runtime (benchmark scripts + implementation)
node|brew install node|Node.js runtime
c3c|brew install c3c|C3 compiler
dotnet|brew install dotnet-sdk|.NET SDK (C# / F#)
elixir|brew install elixir|Elixir runtime (includes Erlang tooling)
escript|brew install erlang|Erlang escript (OTP runtime for Erlang implementation)
gleam|brew install gleam|Gleam CLI (requires Erlang)
gfortran|brew install gcc|GNU Fortran compiler
go|brew install go|Go toolchain
javac|brew install openjdk|Java JDK (javac + java)
kotlinc|brew install kotlin|Kotlin compiler (requires JDK)
julia|brew install julia|Julia runtime
sbcl|brew install sbcl|SBCL (Common Lisp)
lua|brew install lua|Lua runtime
nim|brew install nim|Nim compiler
ocamlopt|brew install ocaml|OCaml compiler
php|brew install php|PHP runtime
ruby|brew install ruby|Ruby runtime
cargo|brew install rust|Rust toolchain (cargo + rustc)
zig|brew install zig|Zig compiler
bc|brew install bc|bc calculator (used for metric averages)
EOF

# Special handling for timeout: accept either timeout or gtimeout
if ! command -v timeout >/dev/null 2>&1; then
  if command -v gtimeout >/dev/null 2>&1; then
    add_missing "timeout" "sudo ln -sf $(command -v gtimeout) /usr/local/bin/timeout" "Symlink GNU timeout (gtimeout) to timeout"
  else
    add_missing "timeout" "brew install coreutils && sudo ln -sf /opt/homebrew/bin/gtimeout /usr/local/bin/timeout" "GNU timeout command (required by benchmark orchestrator)"
  fi
fi

# Perl module check: Parallel::ForkManager and Sys::CPU
if ! perl -MParallel::ForkManager -MSys::CPU -e 1 >/dev/null 2>&1; then
  add_missing "Perl modules" "cpan install Parallel::ForkManager Sys::CPU" "Perl dependencies for threaded implementation"
fi

# OCaml optional dependency: ocamlfind/domainslib improves performance but script falls back
if command -v ocamlopt >/dev/null 2>&1 && ! ocamlfind printconf >/dev/null 2>&1; then
  add_missing "ocamlfind" "opam install ocamlfind" "OCaml findlib (enables parallel build)"
fi
if command -v ocamlfind >/dev/null 2>&1 && ! ocamlfind query domainslib >/dev/null 2>&1; then
  add_missing "domainslib" "opam install domainslib" "OCaml Domainslib (parallel runtime support)"
fi

if [[ ${#missing_cmds[@]} -eq 0 ]]; then
  echo "✅ All required toolchains appear to be installed."
  exit 0
fi

printf "\nMissing dependencies (%d):\n" "${#missing_cmds[@]}"
for idx in "${!missing_cmds[@]}"; do
  cmd=${missing_cmds[$idx]}
  install=${missing_installs[$idx]}
  desc=${missing_descs[$idx]}
  echo "- ${cmd}: ${desc}"
  if [[ "$install" == "System default" ]]; then
    continue
  fi
  if [[ "$install" == xcode-select* ]]; then
    echo "    Install manually: $install"
    continue
  fi
  if [[ "$install" == opam* ]]; then
    echo "    Install with opam: $install"
    continue
  fi
  if [[ "$install" == cpan* ]]; then
    echo "    Install with CPAN: $install"
    continue
  fi
  if [[ "$install" == sudo* ]]; then
    echo "    Run: $install"
    continue
  fi
  if [[ "$install" == brew* ]]; then
    if $BREW_AVAILABLE; then
      if $AUTO_INSTALL; then
        echo "    ↳ Running: $install"
        eval "$install"
      else
        echo "    Install with Homebrew: $install"
      fi
    else
      echo "    (Install Homebrew first, then run: $install)"
    fi
    continue
  fi
  echo "    Install command: $install"

done

if $AUTO_INSTALL; then
  printf "\nAuto-install attempt completed. Re-run without --install to recheck.\n"
else
  printf "\nTip: re-run with --install to let the script invoke Homebrew for supported packages.\n"
fi