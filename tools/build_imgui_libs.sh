#!/usr/bin/env bash
# Build cimgui docking + SDL2/OpenGL3 backends into a single static archive.
# Idempotent: exits immediately if the library is already up to date.
#
# Pinned upstream versions:
#   cimgui  053280dfff63a74cc56a3e493671bee4bb6c60e4  (branch docking_inter)
#           https://github.com/cimgui/cimgui.git
#   imgui   b61e56346a92cfcaf1f43a545ca37b0b32239654  (tag v1.92.8-docking)
#           https://github.com/ocornut/imgui.git
#
# On a fresh clone, run:
#   git submodule update --init --recursive
# or let this script auto-clone (it clones + checks out the pinned SHAs if
# extern/cimgui is absent).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/lib/libcimgui_docking.a"

CIMGUI_SHA="053280dfff63a74cc56a3e493671bee4bb6c60e4"
IMGUI_SHA="b61e56346a92cfcaf1f43a545ca37b0b32239654"

# ── Ensure upstreams are present ──────────────────────────────────────────────
CIMGUI="$ROOT/extern/cimgui"
IMGUI="$CIMGUI/imgui"

if [ ! -f "$CIMGUI/cimgui.cpp" ]; then
    echo "build_imgui_libs.sh: cloning cimgui at $CIMGUI_SHA ..."
    git clone https://github.com/cimgui/cimgui.git "$CIMGUI"
    git -C "$CIMGUI" checkout "$CIMGUI_SHA"
fi
if [ ! -f "$IMGUI/imgui.cpp" ]; then
    echo "build_imgui_libs.sh: cloning imgui at $IMGUI_SHA ..."
    git clone https://github.com/ocornut/imgui.git "$IMGUI"
    git -C "$IMGUI" checkout "$IMGUI_SHA"
fi

# Re-build only when source or this script is newer than the archive.
if [ -f "$OUT" ]; then
    newer=$(find "$CIMGUI" "$ROOT/source/imgui_vibe3d.cpp" "$0" \
            -newer "$OUT" -print -quit 2>/dev/null || true)
    if [ -z "$newer" ]; then
        echo "build_imgui_libs.sh: library up to date, skipping build"
        exit 0
    fi
fi

# ── Locate SDL2 C headers ─────────────────────────────────────────────────────
# Prefer system pkg-config; fall back to the bundled SDL2 headers under D-Cycles
# (which is already a dependency of this machine's vibe3d build environment).
SDL_CFLAGS=""
if pkg-config --exists sdl2 2>/dev/null; then
    SDL_CFLAGS="$(pkg-config --cflags sdl2)"
else
    SDL_CANDIDATES=(
        # D-Cycles ships SDL2 headers on Linux x64
        "$HOME/Code/D-Cycles/extern/blender/lib/linux_x64/sdl/include"
        # dub-cached copies from D-Cycles
        "$HOME/.dub/packages/d-cycles/~master/d-cycles/extern/blender/lib/linux_x64/sdl/include"
        # standard paths
        "/usr/include/SDL2"
        "/usr/local/include/SDL2"
    )
    for d in "${SDL_CANDIDATES[@]}"; do
        if [ -f "$d/SDL.h" ]; then
            SDL_CFLAGS="-I$d"
            echo "build_imgui_libs.sh: using SDL2 headers from $d"
            break
        fi
    done
    if [ -z "$SDL_CFLAGS" ]; then
        echo "ERROR: SDL2 C headers not found. Install libsdl2-dev or ensure" >&2
        echo "       D-Cycles is checked out at ~/Code/D-Cycles." >&2
        exit 1
    fi
fi

CXX="${CXX:-g++}"
# NOTE: do NOT add -DCIMGUI_DEFINE_ENUMS_AND_STRUCTS here — that flag is for
# pure-C consumers of cimgui.h.  When compiling the C++ source files the types
# are already defined by imgui.h / imgui_internal.h; the macro would redefine
# them as C structs and cause enum/struct conflict errors.
CXXFLAGS="-std=c++17 -fPIC -O2 $SDL_CFLAGS"
CXXFLAGS="$CXXFLAGS -I$CIMGUI -I$IMGUI"

BACKEND_FLAGS="$CXXFLAGS -DCIMGUI_USE_SDL2 -DCIMGUI_USE_OPENGL3"
BACKEND_FLAGS="$BACKEND_FLAGS -I$IMGUI/backends"

TMPDIR_BUILD="$(mktemp -d /tmp/cimgui_build.XXXXXX)"
trap 'rm -rf "$TMPDIR_BUILD"' EXIT

echo "build_imgui_libs.sh: compiling cimgui + imgui + backends..."

# ── Patch cimgui.cpp ─────────────────────────────────────────────────────────
# cimgui.cpp's generator and the imgui submodule can be slightly out of sync:
# three functions use C struct pointer types (ImVector_ImGuiID* etc.) where the
# C++ API expects ImVector<T>*.  Both have identical memory layout, so a
# reinterpret_cast is safe.  We patch the generated file into a temp copy to
# avoid modifying the submodule.
CIMGUI_PATCHED="$TMPDIR_BUILD/cimgui_patched.cpp"
sed \
    -e 's/ImGui::DockBuilderCopyNode(\(.*\),out_node_remap_pairs)/ImGui::DockBuilderCopyNode(\1,reinterpret_cast<ImVector<ImGuiID>*>(out_node_remap_pairs))/' \
    -e 's/ImGui::DebugNodeWindowsList(windows,/ImGui::DebugNodeWindowsList(reinterpret_cast<ImVector<ImGuiWindow*>*>(windows),/' \
    -e 's/IM_NEW(ImVector<ImWchar>)()/reinterpret_cast<ImVector_ImWchar*>(IM_NEW(ImVector<ImWchar>)())/' \
    -e 's/p->~ImVector<ImWchar>()/reinterpret_cast<ImVector<ImWchar>*>(p)->~ImVector<ImWchar>()/' \
    "$CIMGUI/cimgui.cpp" > "$CIMGUI_PATCHED"

# ── Compile all sources ───────────────────────────────────────────────────────
compile() {
    local src="$1"
    local flags="${2:-$CXXFLAGS}"
    local obj="$TMPDIR_BUILD/$(basename "${src%.cpp}.o")"
    "$CXX" $flags -c "$src" -o "$obj"
    echo "$obj"
}

OBJS=()
OBJS+=("$(compile "$CIMGUI_PATCHED")")
OBJS+=("$(compile "$IMGUI/imgui.cpp")")
OBJS+=("$(compile "$IMGUI/imgui_draw.cpp")")
OBJS+=("$(compile "$IMGUI/imgui_tables.cpp")")
OBJS+=("$(compile "$IMGUI/imgui_widgets.cpp")")
OBJS+=("$(compile "$IMGUI/imgui_demo.cpp")")
OBJS+=("$(compile "$IMGUI/backends/imgui_impl_sdl2.cpp" "$BACKEND_FLAGS")")
OBJS+=("$(compile "$IMGUI/backends/imgui_impl_opengl3.cpp" "$BACKEND_FLAGS")")

# vibe3d-specific C++ wrapper (Image compat, IO accessors, SDL2 init shim, etc.)
OBJS+=("$(compile "$ROOT/source/imgui_vibe3d.cpp" "$BACKEND_FLAGS")")

mkdir -p "$ROOT/lib"
ar rcs "$OUT" "${OBJS[@]}"
echo "build_imgui_libs.sh: wrote $OUT"

# ── libSDL2.so stub symlink ───────────────────────────────────────────────────
# imgui_impl_sdl2.cpp calls SDL2 C functions directly; the linker must resolve
# them at link time even though bindbc-sdl loads the same library at runtime
# via dlopen.  Systems without libsdl2-devel only ship the versioned .so.0 and
# have no libSDL2.so symlink.  We create one under lib/ so -lSDL2 works.
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
