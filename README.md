# D-ImGui

Static D bindings for [Dear ImGui](https://github.com/ocornut/imgui) (docking branch)
via [cimgui](https://github.com/cimgui/cimgui), with SDL2 and OpenGL3 backend
bindings and an `ImGui.*` module-level shim surface.

Used as the GUI layer for [vibe3d](https://github.com/shulc/vibe3d).

## Layout

```
source/
  d_imgui/          Module d_imgui — the core ImGui API surface
    imgui_h.d         ImGui types, enums, structs
    imgui_cimgui.d    extern(C) declarations for the cimgui C ABI
    imgui_demo.d      ShowDemoWindow binding
    imconfig.d        Project-local compile-time config (ImTextureID = int)
    package.d         Convenience re-exports; `import ImGui = d_imgui;`
  imgui_impl_opengl3.d   D extern(C) declarations for the OpenGL3 backend
  imgui_impl_sdl2.d      D extern(C) declarations for the SDL2 backend
  imgui_vibe3d.cpp       C-linkage shim wrappers compiled into libcimgui_docking.a
tools/
  build_imgui_libs.sh    Builds lib/libcimgui_docking.a from pinned upstreams
```

## Pinned upstream versions

| Library | Commit | Notes |
|---------|--------|-------|
| cimgui  | `053280dfff63a74cc56a3e493671bee4bb6c60e4` | branch `docking_inter` |
| imgui   | `b61e56346a92cfcaf1f43a545ca37b0b32239654` | tag `v1.92.8-docking` |

## First build

`dub build` runs `tools/build_imgui_libs.sh` automatically as a
`preBuildCommands` step. The script is idempotent — it skips the build if
`lib/libcimgui_docking.a` is already up to date.

On a fresh clone the `extern/cimgui` upstream is absent; the build script
auto-clones it (and `extern/cimgui/imgui`) at the pinned SHAs above.
Alternatively, init the git submodule yourself:

```bash
git submodule update --init --recursive
dub build
```

Requires: `g++` (C++17), `pkg-config` (for SDL2 headers), or SDL2 headers
accessible via the D-Cycles checkout at `~/Code/D-Cycles`.

## License

Dear ImGui — MIT License, Copyright (c) 2014-2025 Omar Cornut
cimgui — MIT License, Copyright (c) 2015 Stephan Dilly
imgui_impl_sdl2 / imgui_impl_opengl3 backends — MIT License (Dear ImGui project)
D bindings and shim (this repo) — MIT License

See [LICENSE](LICENSE) for the full text.
