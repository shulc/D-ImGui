// imgui_vibe3d.cpp
// Compatibility shim layer between cimgui 1.92.8 and vibe3d's existing D call sites.
// All functions are exported as plain C symbols.
//
// IMPORTANT: include ONLY imgui.h here, not cimgui.h with
// CIMGUI_DEFINE_ENUMS_AND_STRUCTS — both define the same structs and combining
// them causes redefinition errors.  cimgui's own C wrappers live in cimgui.cpp
// (same archive); we use the C++ API directly from imgui.h.
//
// Key API changes from imgui 1.89.7 → 1.92.8 handled here:
//   - ImGui::Image now takes ImTextureRef, not ImTextureID directly
//   - PushFont now takes 2 args (font, size)
//   - GetForeground/BackgroundDrawList accept an optional viewport*
//   - ImGuiIO / ImGuiStyle fields accessed through C++ class methods
//   - ImTextureID is now ImU64 (uint64_t)
//   - ImGui_ImplSDL2_Init(window) replaced by InitForOpenGL(window, ctx)

#include "../extern/cimgui/imgui/imgui.h"
#include "../extern/cimgui/imgui/backends/imgui_impl_sdl2.h"
#include "../extern/cimgui/imgui/backends/imgui_impl_opengl3.h"
#include <SDL.h>

extern "C" {

// ── Colour macro ─────────────────────────────────────────────────────────────
ImU32 igVibe3d_Col32(int r, int g, int b, int a)
{
    return IM_COL32(r, g, b, a);
}

// ── Version check ────────────────────────────────────────────────────────────
void igVibe3d_CheckVersion(void)
{
    IMGUI_CHECKVERSION();
}

// ── Image ─────────────────────────────────────────────────────────────────────
// Old vibe3d call:  ImGui.Image(cast(ImTextureID) glTex, size, uv0, uv1)
// Old API:          Image(ImTextureID, ImVec2, ImVec2, ImVec2)
// New API (1.92.x): Image(ImTextureRef, const ImVec2&, const ImVec2&, const ImVec2&)
// ImTextureRef has a constructor that takes ImTextureID directly.
// vibe3d's ImTextureID is defined as int in imconfig.d; we receive it as int
// and zero-extend to ImTextureID (ImU64) so GL texture handles work correctly.
void igVibe3d_Image(int texId, float w, float h,
                    float u0, float v0, float u1, float v1)
{
    ImGui::Image(ImTextureRef((ImTextureID)(unsigned int)texId),
                 ImVec2(w, h), ImVec2(u0, v0), ImVec2(u1, v1));
}

// ── PushFont ─────────────────────────────────────────────────────────────────
// Old API: PushFont(ImFont*)            — 1 arg
// New API: PushFont(ImFont*, float)     — 2 args (0 = inherit size)
void igVibe3d_PushFont(ImFont* font)
{
    ImGui::PushFont(font, 0.0f);
}

// ── Draw-list helpers ─────────────────────────────────────────────────────────
// Old API: GetForegroundDrawList() / GetBackgroundDrawList() with no args.
// New API: optional viewport* (nullptr = current viewport).
ImDrawList* igVibe3d_GetForegroundDrawList(void)
{
    return ImGui::GetForegroundDrawList();
}

ImDrawList* igVibe3d_GetBackgroundDrawList(void)
{
    return ImGui::GetBackgroundDrawList();
}

// ── ImGuiIO field accessors ───────────────────────────────────────────────────
// ConfigFlagsPtr: returns a pointer to the ConfigFlags field so D can use
// it as a ref int and support compound-assignment operators (io.ConfigFlags |= X).
int* igVibe3d_IO_ConfigFlagsPtr(ImGuiIO* io)
{
    return reinterpret_cast<int*>(&io->ConfigFlags);
}


// The ImGuiIO struct layout changes between imgui versions; expose stable
// named C-linkage accessors rather than mirroring the layout in D.

int  igVibe3d_IO_GetConfigFlags(ImGuiIO* io)        { return io->ConfigFlags; }
void igVibe3d_IO_SetConfigFlags(ImGuiIO* io, int v) { io->ConfigFlags = (ImGuiConfigFlags)v; }

bool igVibe3d_IO_WantCaptureMouse(ImGuiIO* io)    { return io->WantCaptureMouse; }
bool igVibe3d_IO_WantCaptureKeyboard(ImGuiIO* io) { return io->WantCaptureKeyboard; }
bool igVibe3d_IO_WantTextInput(ImGuiIO* io)       { return io->WantTextInput; }
bool igVibe3d_IO_KeyCtrl(ImGuiIO* io)             { return io->KeyCtrl; }

void igVibe3d_IO_SetIniFilename(ImGuiIO* io, const char* s) { io->IniFilename = s; }

ImFontAtlas* igVibe3d_IO_Fonts(ImGuiIO* io)  { return io->Fonts; }
float igVibe3d_IO_DisplaySizeX(ImGuiIO* io)  { return io->DisplaySize.x; }
float igVibe3d_IO_DisplaySizeY(ImGuiIO* io)  { return io->DisplaySize.y; }

void igVibe3d_IO_AddKeyEvent(ImGuiIO* io, ImGuiKey key, bool down)
{
    io->AddKeyEvent(key, down);
}

// ── ImFontAtlas ───────────────────────────────────────────────────────────────
// cimgui 1.92.8 omitted the ImFontAtlas_Build binding (marked "called
// automatically by GetTexData***").  Provide it so D call sites compile.
bool ImFontAtlas_Build(ImFontAtlas* self)
{
    return self->Build();
}

// ── ImGuiStyle field accessors ────────────────────────────────────────────────
float igVibe3d_Style_ItemSpacingX(ImGuiStyle* s) { return s->ItemSpacing.x; }
float igVibe3d_Style_ItemSpacingY(ImGuiStyle* s) { return s->ItemSpacing.y; }

// ── SDL2 backend C-linkage wrappers ──────────────────────────────────────────
// The imgui backends compile with IMGUI_IMPL_API = "" (no extern "C"), so
// their functions get C++ name-mangled symbols.  D's extern(C) declarations
// need plain C symbols.  Forward each entry point through a wrapper here.

// ImGui_ImplSDL2_Init(window): 1-arg compat shim for the old API.
// Calls InitForOpenGL with the already-current GL context.
bool ImGui_ImplSDL2_Init(SDL_Window* window)
{
    return ImGui_ImplSDL2_InitForOpenGL(window, SDL_GL_GetCurrentContext());
}

void ImGui_ImplSDL2_Shutdown_C(void)   { ImGui_ImplSDL2_Shutdown(); }
void ImGui_ImplSDL2_NewFrame_C(void)   { ImGui_ImplSDL2_NewFrame(); }
bool ImGui_ImplSDL2_ProcessEvent_C(const SDL_Event* e)
{
    return ImGui_ImplSDL2_ProcessEvent(e);
}

// ── OpenGL3 backend C-linkage wrappers ───────────────────────────────────────
bool ImGui_ImplOpenGL3_Init_C(const char* glsl_version)
{
    return ImGui_ImplOpenGL3_Init(glsl_version);
}
void ImGui_ImplOpenGL3_Shutdown_C(void)  { ImGui_ImplOpenGL3_Shutdown(); }
void ImGui_ImplOpenGL3_NewFrame_C(void)  { ImGui_ImplOpenGL3_NewFrame(); }
void ImGui_ImplOpenGL3_RenderDrawData_C(ImDrawData* draw_data)
{
    ImGui_ImplOpenGL3_RenderDrawData(draw_data);
}

} // extern "C"
