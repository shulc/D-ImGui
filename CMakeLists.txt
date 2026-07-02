cmake_minimum_required(VERSION 3.16)

# CMP0091 lets CMAKE_MSVC_RUNTIME_LIBRARY select the MSVC runtime; must be
# set before the first project() call.
if(POLICY CMP0091)
  cmake_policy(SET CMP0091 NEW)
endif()

project(cimgui_docking LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

if(MSVC)
  # Dynamic CRT (/MD), matching what LDC/dub links against on Windows.
  # Mirrors D-Assimp's build_assimp_min.sh, already proven on this project's
  # Windows CI runner.
  set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDLL")
endif()

set(D_IMGUI_ROOT ${CMAKE_CURRENT_SOURCE_DIR})
set(CIMGUI_DIR ${D_IMGUI_ROOT}/extern/cimgui)
set(IMGUI_DIR ${CIMGUI_DIR}/imgui)

if(NOT EXISTS ${CIMGUI_DIR}/cimgui.cpp)
  message(FATAL_ERROR
    "cimgui source not found at ${CIMGUI_DIR}. Run:\n"
    "  git submodule update --init --recursive extern/cimgui")
endif()
if(NOT EXISTS ${IMGUI_DIR}/imgui.cpp)
  message(FATAL_ERROR
    "imgui source not found at ${IMGUI_DIR} (nested submodule of "
    "extern/cimgui). Run:\n"
    "  git submodule update --init --recursive extern/cimgui")
endif()

# ── Patch cimgui.cpp (build-time, not just configure-time, so editing
#    cimgui.cpp — e.g. a future submodule bump — re-triggers the patch) ─────
set(CIMGUI_PATCHED_CPP ${CMAKE_CURRENT_BINARY_DIR}/cimgui_patched.cpp)
add_custom_command(
  OUTPUT ${CIMGUI_PATCHED_CPP}
  COMMAND ${CMAKE_COMMAND}
          -DIN=${CIMGUI_DIR}/cimgui.cpp
          -DOUT=${CIMGUI_PATCHED_CPP}
          -P ${D_IMGUI_ROOT}/cmake/patch_cimgui.cmake
  DEPENDS ${CIMGUI_DIR}/cimgui.cpp ${D_IMGUI_ROOT}/cmake/patch_cimgui.cmake
  COMMENT "Patching cimgui.cpp (ImVector C/C++ struct-pointer casts)"
  VERBATIM
)

# ── SDL2 headers ─────────────────────────────────────────────────────────
# Only C headers are needed here (imgui_impl_sdl2.cpp + imgui_vibe3d.cpp
# call SDL2 functions directly). Actual link-time SDL2 resolution happens
# later, at vibe3d's own dub link, via lflags-linux/-osx/-windows.
set(SDL2_INCLUDE_DIR_RESOLVED "")

if(DEFINED ENV{SDL2_DIR} AND EXISTS "$ENV{SDL2_DIR}/include/SDL.h")
  # Windows SDL2-devel-VC zip layout: build.yml downloads it and exports
  # SDL2_DIR to the extracted root (headers live directly under include/).
  # Also honored on Unix if a caller happens to set it.
  set(SDL2_INCLUDE_DIR_RESOLVED "$ENV{SDL2_DIR}/include")
  message(STATUS "cimgui_docking: SDL2 headers from \$SDL2_DIR = $ENV{SDL2_DIR}")
endif()

if(NOT SDL2_INCLUDE_DIR_RESOLVED)
  find_package(SDL2 QUIET)
  if(SDL2_FOUND)
    if(TARGET SDL2::SDL2)
      get_target_property(SDL2_INCLUDE_DIR_RESOLVED SDL2::SDL2 INTERFACE_INCLUDE_DIRECTORIES)
    elseif(DEFINED SDL2_INCLUDE_DIRS)
      set(SDL2_INCLUDE_DIR_RESOLVED "${SDL2_INCLUDE_DIRS}")
    endif()
    if(SDL2_INCLUDE_DIR_RESOLVED)
      message(STATUS "cimgui_docking: SDL2 headers via find_package(SDL2)")
    endif()
  endif()
endif()

if(NOT SDL2_INCLUDE_DIR_RESOLVED)
  find_package(PkgConfig QUIET)
  if(PKG_CONFIG_FOUND)
    pkg_check_modules(SDL2PC QUIET sdl2)
    if(SDL2PC_FOUND)
      set(SDL2_INCLUDE_DIR_RESOLVED "${SDL2PC_INCLUDE_DIRS}")
      message(STATUS "cimgui_docking: SDL2 headers via pkg-config")
    endif()
  endif()
endif()

if(NOT SDL2_INCLUDE_DIR_RESOLVED)
  find_program(SDL2_CONFIG_EXECUTABLE sdl2-config)
  if(SDL2_CONFIG_EXECUTABLE)
    # sdl2-config resolves the include path for ANY install prefix —
    # notably Homebrew on Apple Silicon (/opt/homebrew), where pkg-config's
    # search path often isn't wired up. Correct on x64 (/usr/local) too.
    execute_process(
      COMMAND ${SDL2_CONFIG_EXECUTABLE} --cflags
      OUTPUT_VARIABLE _sdl2_cflags
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    string(REGEX MATCHALL "-I[^ ]+" _sdl2_inc_flags "${_sdl2_cflags}")
    foreach(_f ${_sdl2_inc_flags})
      string(SUBSTRING "${_f}" 2 -1 _dir)
      list(APPEND SDL2_INCLUDE_DIR_RESOLVED "${_dir}")
    endforeach()
    if(SDL2_INCLUDE_DIR_RESOLVED)
      message(STATUS "cimgui_docking: SDL2 headers via sdl2-config")
    endif()
  endif()
endif()

if(NOT SDL2_INCLUDE_DIR_RESOLVED)
  # Last-resort search — mirrors the previous shell script's candidate list.
  find_path(SDL2_INCLUDE_DIR_FALLBACK SDL.h
    PATHS
      /usr/include/SDL2
      /usr/local/include/SDL2
      /opt/homebrew/include/SDL2
      $ENV{HOME}/Code/D-Cycles/extern/blender/lib/linux_x64/sdl/include
  )
  if(SDL2_INCLUDE_DIR_FALLBACK)
    set(SDL2_INCLUDE_DIR_RESOLVED "${SDL2_INCLUDE_DIR_FALLBACK}")
    message(STATUS "cimgui_docking: SDL2 headers from fallback search: ${SDL2_INCLUDE_DIR_FALLBACK}")
  endif()
endif()

if(NOT SDL2_INCLUDE_DIR_RESOLVED)
  message(FATAL_ERROR
    "SDL2 C headers not found. Install libsdl2-dev (Linux), run "
    "'brew install sdl2' (macOS), or set SDL2_DIR to an extracted "
    "SDL2-devel-VC zip root (Windows).")
endif()

# ── The static library ──────────────────────────────────────────────────
add_library(cimgui_docking STATIC
  ${CIMGUI_PATCHED_CPP}
  ${IMGUI_DIR}/imgui.cpp
  ${IMGUI_DIR}/imgui_draw.cpp
  ${IMGUI_DIR}/imgui_tables.cpp
  ${IMGUI_DIR}/imgui_widgets.cpp
  ${IMGUI_DIR}/imgui_demo.cpp
  ${IMGUI_DIR}/backends/imgui_impl_sdl2.cpp
  ${IMGUI_DIR}/backends/imgui_impl_opengl3.cpp
  ${D_IMGUI_ROOT}/source/imgui_vibe3d.cpp
)

# Pin the output to lib/ regardless of single-config (Ninja/Makefiles) vs
# multi-config (Visual Studio) generator — the latter would otherwise nest
# artifacts under lib/Release/, breaking dub.json's fixed lflags path.
set_target_properties(cimgui_docking PROPERTIES
  ARCHIVE_OUTPUT_DIRECTORY                 ${D_IMGUI_ROOT}/lib
  ARCHIVE_OUTPUT_DIRECTORY_RELEASE         ${D_IMGUI_ROOT}/lib
  ARCHIVE_OUTPUT_DIRECTORY_DEBUG           ${D_IMGUI_ROOT}/lib
  ARCHIVE_OUTPUT_DIRECTORY_RELWITHDEBINFO  ${D_IMGUI_ROOT}/lib
  ARCHIVE_OUTPUT_DIRECTORY_MINSIZEREL      ${D_IMGUI_ROOT}/lib
  POSITION_INDEPENDENT_CODE ON
)

target_include_directories(cimgui_docking PRIVATE
  ${CIMGUI_DIR}
  ${IMGUI_DIR}
  ${IMGUI_DIR}/backends
  ${SDL2_INCLUDE_DIR_RESOLVED}
)

# CIMGUI_USE_SDL2 / CIMGUI_USE_OPENGL3 mirror the previous shell script's
# BACKEND_FLAGS: only the backend + vibe3d shim compile units need them.
set_source_files_properties(
  ${IMGUI_DIR}/backends/imgui_impl_sdl2.cpp
  ${IMGUI_DIR}/backends/imgui_impl_opengl3.cpp
  ${D_IMGUI_ROOT}/source/imgui_vibe3d.cpp
  PROPERTIES COMPILE_DEFINITIONS "CIMGUI_USE_SDL2;CIMGUI_USE_OPENGL3"
)

# NOTE: do NOT add -DCIMGUI_DEFINE_ENUMS_AND_STRUCTS — that flag is for
# pure-C consumers of cimgui.h. When compiling the C++ source files the
# types are already defined by imgui.h / imgui_internal.h; the macro would
# redefine them as C structs and cause enum/struct conflict errors.

if(MSVC)
  # Standard MSVC C++ exception-handling model flag; CMake does not add it
  # by default. Not empirically verified on Windows CI — see the plan doc's
  # "Windows assumptions" note.
  target_compile_options(cimgui_docking PRIVATE /EHsc)
endif()

# imgui.cpp pulls in user32/kernel32/shell32/imm32 via #pragma comment(lib,
# ...) on _WIN32, so no explicit libs-windows entries are needed for those.
