/// imgui_impl_opengl3 — thin D declarations for the OpenGL3 backend.
/// The actual implementation is compiled into libcimgui_docking.a from
/// imgui/backends/imgui_impl_opengl3.cpp + C-linkage wrappers in imgui_vibe3d.cpp.
module imgui_impl_opengl3;

import d_imgui.imgui_h : ImDrawData;

private extern(C) nothrow @nogc
{
    bool ImGui_ImplOpenGL3_Init_C(const(char)* glsl_version);
    void ImGui_ImplOpenGL3_Shutdown_C();
    void ImGui_ImplOpenGL3_NewFrame_C();
    void ImGui_ImplOpenGL3_RenderDrawData_C(ImDrawData* draw_data);
}

nothrow @nogc:

bool ImGui_ImplOpenGL3_Init(const(char)* glsl_version)
{
    return ImGui_ImplOpenGL3_Init_C(glsl_version);
}

void ImGui_ImplOpenGL3_Shutdown()  { ImGui_ImplOpenGL3_Shutdown_C(); }
void ImGui_ImplOpenGL3_NewFrame()  { ImGui_ImplOpenGL3_NewFrame_C(); }

void ImGui_ImplOpenGL3_RenderDrawData(ImDrawData* draw_data)
{
    ImGui_ImplOpenGL3_RenderDrawData_C(draw_data);
}
