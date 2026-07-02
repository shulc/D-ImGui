#!/usr/bin/env bash
# build_imgui_libs.sh — portable native build for D-ImGui.
#
# Drives CMake to compile cimgui (docking branch) + imgui core + the SDL2 /
# OpenGL3 backends + vibe3d's C++ shim (source/imgui_vibe3d.cpp) into a
# single static archive:
#   lib/libcimgui_docking.a   (Linux / macOS)
#   lib/cimgui_docking.lib    (Windows / MSVC)
#
# Cross-platform: runs under a plain POSIX shell on Linux/macOS, and under
# Git Bash on Windows (dub.json's preBuildCommands-windows invokes it via
# `bash -lc "..."`) — mirrors the bindbc-assimp6 / D-Assimp static-build
# pattern (tools/build_assimp_min.sh), already proven on this project's
# Windows CI runner.
#
# Idempotent: dub.json's outer `test -f lib/... ||` guard skips invoking
# this script at all once the archive exists. If invoked directly (e.g. by
# hand during D-ImGui development) it additionally re-checks staleness
# against sources and skips the rebuild when nothing changed.
#
# Pinned upstream versions (extern/cimgui submodule + its nested imgui
# submodule — see .gitmodules):
#   cimgui  053280dfff63a74cc56a3e493671bee4bb6c60e4  (branch docking_inter)
#           https://github.com/cimgui/cimgui.git
#   imgui   b61e56346a92cfcaf1f43a545ca37b0b32239654  (tag v1.92.8-docking)
#           https://github.com/ocornut/imgui.git
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT/build"
CIMGUI="$ROOT/extern/cimgui"
IMGUI="$CIMGUI/imgui"

is_windows_shell() {
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
    *) return 1 ;;
  esac
}

# CMake is a native Windows executable even when invoked from Git Bash; MSYS
# paths like /c/Users/... must be converted to C:\Users\... for it.
cmake_path() {
  if is_windows_shell; then
    cygpath -w "$1"
  else
    printf '%s\n' "$1"
  fi
}

if is_windows_shell; then
  OUT="$ROOT/lib/cimgui_docking.lib"
else
  OUT="$ROOT/lib/libcimgui_docking.a"
fi

# ── Ensure submodule sources are present ──────────────────────────────────
# dub.json's preBuildCommands already run `git submodule update --init
# --recursive` before invoking this script; this is a defensive fallback
# for direct/manual invocation (mirrors the previous script's auto-clone
# path, in case someone runs this script outside of a dub build).
if [ ! -f "$CIMGUI/cimgui.cpp" ] || [ ! -f "$IMGUI/imgui.cpp" ]; then
  if [ -e "$ROOT/.git" ]; then
    echo "build_imgui_libs.sh: initializing submodules ..."
    git -C "$ROOT" submodule sync --quiet extern/cimgui
    git -C "$ROOT" submodule update --init --recursive --quiet extern/cimgui
  fi
fi
if [ ! -f "$CIMGUI/cimgui.cpp" ]; then
  CIMGUI_SHA="053280dfff63a74cc56a3e493671bee4bb6c60e4"
  echo "build_imgui_libs.sh: cloning cimgui at $CIMGUI_SHA ..."
  git clone https://github.com/cimgui/cimgui.git "$CIMGUI"
  git -C "$CIMGUI" checkout "$CIMGUI_SHA"
fi
if [ ! -f "$IMGUI/imgui.cpp" ]; then
  IMGUI_SHA="b61e56346a92cfcaf1f43a545ca37b0b32239654"
  echo "build_imgui_libs.sh: cloning imgui at $IMGUI_SHA ..."
  git clone https://github.com/ocornut/imgui.git "$IMGUI"
  git -C "$IMGUI" checkout "$IMGUI_SHA"
fi

# ── Skip rebuild if the archive is already newer than every input ────────
if [ -f "$OUT" ]; then
  newer=$(find "$CIMGUI" "$ROOT/source/imgui_vibe3d.cpp" "$ROOT/CMakeLists.txt" \
               "$ROOT/cmake/patch_cimgui.cmake" "$0" \
          -newer "$OUT" -print -quit 2>/dev/null || true)
  if [ -z "$newer" ]; then
    echo "build_imgui_libs.sh: library up to date, skipping build"
    exit 0
  fi
fi

command -v cmake >/dev/null 2>&1 || { echo "ERROR: cmake not found on PATH." >&2; exit 1; }

GEN=()
if command -v ninja >/dev/null 2>&1; then
  GEN=(-G Ninja)
elif command -v make >/dev/null 2>&1; then
  GEN=()   # default Unix Makefiles generator
elif ! is_windows_shell; then
  echo "ERROR: neither ninja nor make found." >&2
  exit 1
fi
# On Windows, if neither ninja nor make is on PATH, fall through to CMake's
# own default generator selection (Visual Studio + MSBuild). Untested here —
# see doc/imgui_binding_portable_build_plan.md's Windows-assumptions note;
# ninja is expected to be present (bindbc-assimp6's build already relies on
# it succeeding on this project's Windows CI runner).

JOBS="$(nproc 2>/dev/null || echo 4)"

CMAKE_SRC="$(cmake_path "$ROOT")"
CMAKE_BUILD_DIR="$(cmake_path "$BUILD_DIR")"

echo "build_imgui_libs.sh: configuring ..."
cmake "${GEN[@]}" -S "$CMAKE_SRC" -B "$CMAKE_BUILD_DIR" -DCMAKE_BUILD_TYPE=Release

echo "build_imgui_libs.sh: building (-j$JOBS) ..."
cmake --build "$CMAKE_BUILD_DIR" -j"$JOBS" --config Release --target cimgui_docking

if [ ! -f "$OUT" ]; then
  echo "ERROR: expected archive not found at $OUT after build." >&2
  exit 1
fi
echo "build_imgui_libs.sh: wrote $OUT"

# ── libSDL2.so stub symlink (Linux/macOS link-time convenience) ──────────
# imgui_impl_sdl2.cpp + imgui_vibe3d.cpp call SDL2 C functions directly; the
# D-side linker must resolve them at link time even though bindbc-sdl loads
# the same library at runtime via dlopen. Systems without libsdl2-devel only
# ship the versioned .so.0 and have no libSDL2.so symlink — create one under
# lib/ so -lSDL2 works. Unchanged from the previous script. Windows resolves
# SDL2 via lflags-windows -> $SDL2_DIR/lib/x64/SDL2.lib instead.
if ! is_windows_shell; then
  SDL_STUB="$ROOT/lib/libSDL2.so"
  if [ ! -L "$SDL_STUB" ] && [ ! -f "$SDL_STUB" ]; then
    SDL_SO_CANDIDATES=(
        /usr/lib64/libSDL2-2.0.so.0
        /usr/lib/libSDL2-2.0.so.0
        /usr/lib/x86_64-linux-gnu/libSDL2-2.0.so.0
        /lib64/libSDL2-2.0.so.0
    )
    for c in "${SDL_SO_CANDIDATES[@]}"; do
      if [ -f "$c" ]; then
        ln -sf "$c" "$SDL_STUB"
        echo "build_imgui_libs.sh: created libSDL2.so stub → $c"
        break
      fi
    done
    if [ ! -L "$SDL_STUB" ] && [ ! -f "$SDL_STUB" ]; then
      echo "WARNING: could not locate libSDL2-2.0.so.0; -lSDL2 may fail at link time" >&2
    fi
  fi
fi
