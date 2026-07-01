/// imgui_impl_sdl2 — thin D extern(C) declarations for the SDL2 backend.
/// The actual implementation is compiled into libcimgui_docking.a from
/// imgui/backends/imgui_impl_sdl2.cpp + C-linkage wrappers in imgui_vibe3d.cpp.
///
/// Note: ImGui_ImplSDL2_Shutdown / NewFrame / ProcessEvent use _C-suffixed
/// symbols (plain C-linkage wrappers for the otherwise C++-mangled backend
/// functions), aliased here to the original names that app.d expects.
module imgui_impl_sdl2;

import bindbc.sdl : SDL_Window, SDL_Event;

// Init: extern "C" symbol from imgui_vibe3d.cpp — public so app.d can call it directly.
extern(C) nothrow @nogc bool ImGui_ImplSDL2_Init(SDL_Window* window);

private extern(C) nothrow @nogc
{
    // Remaining: provided as _C-wrapped plain-C symbols
    void ImGui_ImplSDL2_Shutdown_C();
    void ImGui_ImplSDL2_NewFrame_C();
    bool ImGui_ImplSDL2_ProcessEvent_C(const(SDL_Event)* event);
}

nothrow @nogc:

/// Shutdown the SDL2 imgui backend.
void ImGui_ImplSDL2_Shutdown() { ImGui_ImplSDL2_Shutdown_C(); }

/// Per-frame update (call before ImGui.NewFrame).
void ImGui_ImplSDL2_NewFrame() { ImGui_ImplSDL2_NewFrame_C(); }

/// Forward one SDL event to imgui.  Returns true if imgui consumed it.
bool ImGui_ImplSDL2_ProcessEvent(const(SDL_Event)* event)
{
    return ImGui_ImplSDL2_ProcessEvent_C(event);
}
