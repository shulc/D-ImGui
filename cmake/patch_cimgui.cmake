# patch_cimgui.cmake — invoked as:
#   cmake -DIN=<path/to/cimgui.cpp> -DOUT=<path/to/patched.cpp> -P patch_cimgui.cmake
#
# cimgui's C++ generator and the pinned imgui submodule are a half step out
# of sync: a few generated wrapper functions pass C struct pointer types
# (ImVector_ImGuiID*, ImVector_ImWchar*, ...) where the underlying C++ API
# now expects the real template type (ImVector<T>*). Both have identical
# memory layout, so a reinterpret_cast resolves it without touching the
# submodule. This is a straight port of the sed substitutions the previous
# tools/build_imgui_libs.sh applied inline.
if(NOT DEFINED IN OR NOT DEFINED OUT)
  message(FATAL_ERROR "patch_cimgui.cmake requires -DIN=<src> -DOUT=<dst>")
endif()

file(READ "${IN}" _src)

string(REPLACE
  "ImGui::DockBuilderCopyNode(src_node_id,dst_node_id,out_node_remap_pairs);"
  "ImGui::DockBuilderCopyNode(src_node_id,dst_node_id,reinterpret_cast<ImVector<ImGuiID>*>(out_node_remap_pairs));"
  _src "${_src}")

string(REPLACE
  "ImGui::DebugNodeWindowsList(windows,label);"
  "ImGui::DebugNodeWindowsList(reinterpret_cast<ImVector<ImGuiWindow*>*>(windows),label);"
  _src "${_src}")

string(REPLACE
  "IM_NEW(ImVector<ImWchar>)()"
  "reinterpret_cast<ImVector_ImWchar*>(IM_NEW(ImVector<ImWchar>)())"
  _src "${_src}")

string(REPLACE
  "p->~ImVector<ImWchar>();"
  "reinterpret_cast<ImVector<ImWchar>*>(p)->~ImVector<ImWchar>();"
  _src "${_src}")

file(WRITE "${OUT}" "${_src}")
