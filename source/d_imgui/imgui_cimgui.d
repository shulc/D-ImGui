/// module d_imgui.imgui_cimgui
/// extern(C) declarations for cimgui 1.92.8 docking branch +
/// vibe3d-specific shim functions from imgui_vibe3d.cpp.
module d_imgui.imgui_cimgui;

// Forward declarations of opaque C++ types.
// ImFontAtlas and ImGuiPayload are NOT listed here — they are defined as full
// D structs (with methods / fields) in imgui_h.d.  Declaring them again here
// would create two different types with the same name, breaking pointer passing.
// Instead, their C function parameters are typed as void* below.
struct ImGuiContext;
struct ImDrawData;
struct ImFont;
struct ImGuiViewport;
// ImGuiDockNode is an opaque docking-graph node; imgui_h.d re-exports this type.
struct ImGuiDockNode;

// Alias types that match the C side.
alias ImU32    = uint;
alias ImU64    = ulong;
alias ImWchar  = ushort;
alias ImGuiID  = uint;

// Struct-value types returned / passed by value from cimgui
// (cimgui uses ImVec2_c / ImVec4_c as typedefs for by-value passing).
extern(C) struct ImVec2_c { float x = 0, y = 0; }
extern(C) struct ImVec4_c { float x = 0, y = 0, z = 0, w = 0; }

// Draw-list flags (bitmask int aliases)
alias ImDrawFlags_        = int;    // used in cimgui C declarations

// Flag typedefs (int aliases on the C side)
alias ImGuiWindowFlags    = int;
alias ImGuiChildFlags     = int;
alias ImGuiComboFlags     = int;
alias ImGuiPopupFlags     = int;
alias ImGuiSelectableFlags = int;
alias ImGuiInputTextFlags = int;
alias ImGuiSliderFlags    = int;
alias ImGuiTreeNodeFlags  = int;
alias ImGuiTabBarFlags    = int;
alias ImGuiTabItemFlags   = int;
alias ImGuiTableFlags     = int;
alias ImGuiButtonFlags    = int;
alias ImGuiDragDropFlags  = int;
alias ImGuiFocusedFlags   = int;
alias ImGuiHoveredFlags   = int;
alias ImGuiCond           = int;
alias ImGuiKey            = int;
alias ImGuiMouseButton    = int;
alias ImGuiMouseCursor    = int;
alias ImGuiConfigFlags    = int;
alias ImGuiDockNodeFlags  = int;
alias ImGuiDir_           = int;
alias ImGuiCol_           = int;
alias ImGuiStyleVar_      = int;

import core.stdc.stdarg : va_list;

extern(C) nothrow @nogc:

// ── Context ───────────────────────────────────────────────────────────────────
// shared_font_atlas is imgui_h.ImFontAtlas* — passed as void* to avoid type conflict.
ImGuiContext* igCreateContext(void* shared_font_atlas);
void          igDestroyContext(ImGuiContext* ctx);

// ── Per-frame ─────────────────────────────────────────────────────────────────
void igNewFrame();
void igRender();
void igEndFrame();
ImDrawData* igGetDrawData();

// ── IO / Style ────────────────────────────────────────────────────────────────
ImGuiContext* igGetCurrentContext();
// These return pointers; the D ImGuiIO / ImGuiStyle opaque wrappers dereference them.
// Declared as void* here to avoid mirroring the huge C++ structs.
// The typed wrappers in imgui_h.d cast through the opaque D structs.
void* igGetIO_Nil();
void* igGetStyle();
void  igStyleColorsDark(void* dst);
// cimgui 1.92.8: igScaleAllSizes was removed; it is now a method on ImGuiStyle.
void  ImGuiStyle_ScaleAllSizes(void* self, float scale_factor);

// ── Windows ───────────────────────────────────────────────────────────────────
bool igBegin(const(char)* name, bool* p_open, ImGuiWindowFlags flags);
void igEnd();
bool igBeginChild_Str(const(char)* str_id, ImVec2_c size,
                      ImGuiChildFlags child_flags, ImGuiWindowFlags window_flags);
bool igBeginChild_ID(ImGuiID id, ImVec2_c size,
                     ImGuiChildFlags child_flags, ImGuiWindowFlags window_flags);
void igEndChild();

// ── Window utilities ──────────────────────────────────────────────────────────
bool igIsWindowAppearing();
void igSetWindowFocus_Nil();
void igSetWindowFocus_Str(const(char)* name);
void igSetNextWindowPos(ImVec2_c pos, ImGuiCond cond, ImVec2_c pivot);
void igSetNextWindowSize(ImVec2_c size, ImGuiCond cond);
void igSetScrollHereY(float center_y_ratio);

// ── Cursor / layout ───────────────────────────────────────────────────────────
ImVec2_c igGetCursorScreenPos();
ImVec2_c igGetCursorPos();
void     igSetCursorPos(ImVec2_c local_pos);
ImVec2_c igGetContentRegionAvail();
void     igSetNextItemWidth(float item_width);
void     igSameLine(float offset_from_start_x, float spacing);
void     igDummy(ImVec2_c size);
void     igSeparator();
void     igSeparatorText(const(char)* label);
void     igAlignTextToFramePadding();
void     igBeginGroup();
void     igEndGroup();

// ── Font metrics ──────────────────────────────────────────────────────────────
float igGetFontSize();
float igGetTextLineHeightWithSpacing();
float igGetFrameHeightWithSpacing();

// ── ID stack ──────────────────────────────────────────────────────────────────
void igPushID_Str(const(char)* str_id);
void igPushID_StrStr(const(char)* str_id_begin, const(char)* str_id_end);
void igPushID_Int(int int_id);
void igPopID();

// ── Style ─────────────────────────────────────────────────────────────────────
void igPushStyleColor_U32(ImGuiCol_ idx, ImU32 col);
void igPushStyleColor_Vec4(ImGuiCol_ idx, ImVec4_c col);
void igPopStyleColor(int count);
void igPushStyleVar_Float(ImGuiStyleVar_ idx, float val);
void igPushStyleVar_Vec2(ImGuiStyleVar_ idx, ImVec2_c val);
void igPopStyleVar(int count);

// ── Font ──────────────────────────────────────────────────────────────────────
void igPopFont();

// ── Text ──────────────────────────────────────────────────────────────────────
void igText(const(char)* fmt, ...);
void igTextV(const(char)* fmt, va_list args);
void igTextColored(ImVec4_c col, const(char)* fmt, ...);
void igTextDisabled(const(char)* fmt, ...);
void igTextUnformatted(const(char)* text, const(char)* text_end);
void igLabelText(const(char)* label, const(char)* fmt, ...);
void igSetTooltip(const(char)* fmt, ...);

// ── Widgets ───────────────────────────────────────────────────────────────────
bool igButton(const(char)* label, ImVec2_c size);
bool igSmallButton(const(char)* label);
bool igCheckbox(const(char)* label, bool* v);
bool igRadioButton_Bool(const(char)* label, bool active);
bool igSelectable_Bool(const(char)* label, bool selected,
                       ImGuiSelectableFlags flags, ImVec2_c size);
bool igInputText(const(char)* label, char* buf, size_t buf_size,
                 ImGuiInputTextFlags flags, void* callback, void* user_data);
bool igInputTextWithHint(const(char)* label, const(char)* hint,
                         char* buf, size_t buf_size,
                         ImGuiInputTextFlags flags, void* callback, void* user_data);
bool igSliderFloat(const(char)* label, float* v, float v_min, float v_max,
                   const(char)* format, ImGuiSliderFlags flags);
bool igSliderInt(const(char)* label, int* v, int v_min, int v_max,
                 const(char)* format, ImGuiSliderFlags flags);
bool igDragFloat(const(char)* label, float* v, float v_speed,
                 float v_min, float v_max, const(char)* format, ImGuiSliderFlags flags);
bool igDragInt(const(char)* label, int* v, float v_speed,
               int v_min, int v_max, const(char)* format, ImGuiSliderFlags flags);
bool igCollapsingHeader_TreeNodeFlags(const(char)* label, ImGuiTreeNodeFlags flags);
void igProgressBar(float fraction, ImVec2_c size_arg, const(char)* overlay);

// ── Combo ─────────────────────────────────────────────────────────────────────
bool igBeginCombo(const(char)* label, const(char)* preview_value, ImGuiComboFlags flags);
void igEndCombo();
bool igCombo_Str_arr(const(char)* label, int* current_item,
                     const(char*)* items, int items_count, int popup_max_height_in_items);

// ── Menus ─────────────────────────────────────────────────────────────────────
bool igBeginMenu(const(char)* label, bool enabled);
void igEndMenu();
bool igMenuItem_Bool(const(char)* label, const(char)* shortcut,
                     bool selected, bool enabled);

// ── Popups ────────────────────────────────────────────────────────────────────
bool igBeginPopup(const(char)* str_id, ImGuiWindowFlags flags);
bool igBeginPopupModal(const(char)* name, bool* p_open, ImGuiWindowFlags flags);
void igEndPopup();
void igOpenPopup_Str(const(char)* str_id, ImGuiPopupFlags popup_flags);
bool igBeginPopupContextItem(const(char)* str_id, ImGuiPopupFlags popup_flags);
bool igBeginPopupContextWindow(const(char)* str_id, ImGuiPopupFlags popup_flags);
void igCloseCurrentPopup();

// ── Disabled ──────────────────────────────────────────────────────────────────
void igBeginDisabled(bool disabled);
void igEndDisabled();

// ── Item queries ──────────────────────────────────────────────────────────────
bool     igIsItemHovered(ImGuiHoveredFlags flags);
bool     igIsItemActive();
bool     igIsItemDeactivated();
bool     igIsItemDeactivatedAfterEdit();
bool     igIsAnyItemActive();
ImVec2_c igGetItemRectMin();
ImVec2_c igGetItemRectMax();
void     igSetItemDefaultFocus();

// ── Text utilities ────────────────────────────────────────────────────────────
ImVec2_c igCalcTextSize(const(char)* text, const(char)* text_end,
                        bool hide_text_after_double_hash, float wrap_width);

// ── Mouse ─────────────────────────────────────────────────────────────────────
// cimgui 1.92.8: overloaded functions get _Nil / _Bool suffixes.
bool     igIsMouseDoubleClicked_Nil(ImGuiMouseButton button);
bool     igIsKeyPressed_Bool(ImGuiKey key, bool repeat);
ImVec2_c igGetMouseDragDelta(ImGuiMouseButton button, float lock_threshold);
void     igResetMouseDragDelta(ImGuiMouseButton button);
void     igSetMouseCursor(ImGuiMouseCursor cursor_type);

// ── Drag & drop ───────────────────────────────────────────────────────────────
bool             igBeginDragDropSource(ImGuiDragDropFlags flags);
void             igEndDragDropSource();
bool             igBeginDragDropTarget();
void             igEndDragDropTarget();
bool             igSetDragDropPayload(const(char)* type_, const(void)* data,
                                      size_t sz, ImGuiCond cond);
// Returns imgui_h.ImGuiPayload* — typed as void* here to avoid the two-type
// conflict; caller in package.d casts to const(ImGuiPayload)*.
const(void)* igAcceptDragDropPayload(const(char)* type_,
                                     ImGuiDragDropFlags flags);

// ── Draw lists ────────────────────────────────────────────────────────────────
void* igGetWindowDrawList();     // returns ImDrawList*, cast in D

// ── Clipboard ─────────────────────────────────────────────────────────────────
void igSetClipboardText(const(char)* text);

// ── Keyboard focus ────────────────────────────────────────────────────────────
void igSetKeyboardFocusHere(int offset);

// ── Draw list methods ─────────────────────────────────────────────────────────
void ImDrawList_AddLine(void* self, ImVec2_c p1, ImVec2_c p2,
                        ImU32 col, float thickness);
void ImDrawList_AddText_Vec2(void* self, ImVec2_c pos, ImU32 col,
                              const(char)* text_begin, const(char)* text_end);
void ImDrawList_AddRectFilled(void* self, ImVec2_c p_min, ImVec2_c p_max,
                               ImU32 col, float rounding, ImDrawFlags_ flags);
// cimgui 1.92.8: thickness comes BEFORE flags (opposite of C++ imgui API order).
// The D wrapper method reorders so callers use C++ API order (flags, then thickness).
void ImDrawList_AddRect(void* self, ImVec2_c p_min, ImVec2_c p_max,
                        ImU32 col, float rounding, float thickness, ImDrawFlags_ flags);
void ImDrawList_AddCircle(void* self, ImVec2_c center, float radius,
                          ImU32 col, int num_segments, float thickness);
void ImDrawList_AddCircleFilled(void* self, ImVec2_c center, float radius,
                                 ImU32 col, int num_segments);
void ImDrawList_AddTriangleFilled(void* self, ImVec2_c p1, ImVec2_c p2,
                                   ImVec2_c p3, ImU32 col);
// cimgui 1.92.8: (col, thickness, flags) — thickness BEFORE flags.
// The D wrapper reorders so callers see C++ API order (col, flags, thickness).
void ImDrawList_AddPolyline(void* self, const(ImVec2_c)* points, int num_points,
                             ImU32 col, float thickness, ImDrawFlags_ flags);
void ImDrawList_AddQuadFilled(void* self, ImVec2_c p1, ImVec2_c p2,
                               ImVec2_c p3, ImVec2_c p4, ImU32 col);
void ImDrawList_AddConvexPolyFilled(void* self, const(ImVec2_c)* points,
                                     int num_points, ImU32 col);
void ImDrawList_PathFillConvex(void* self, ImU32 col);
void ImDrawList_AddBezierCubic(void* self, ImVec2_c p1, ImVec2_c p2,
                                ImVec2_c p3, ImVec2_c p4,
                                ImU32 col, float thickness, int num_segments);
void ImDrawList_PathLineTo(void* self, ImVec2_c pos);
void ImDrawList_PathStroke(void* self, ImU32 col, float thickness, int flags);
void ImDrawList_PathClear(void* self);
void ImDrawList_PushClipRect(void* self, ImVec2_c clip_rect_min,
                              ImVec2_c clip_rect_max, bool intersect_with_current_clip_rect);
void ImDrawList_PopClipRect(void* self);

// ── Font atlas ────────────────────────────────────────────────────────────────
// self is imgui_h.ImFontAtlas* passed as void* to avoid the two-type conflict.
ImFont* ImFontAtlas_AddFontFromMemoryTTF(void* self,
    void* font_data, int font_data_size, float size_pixels,
    const(void)* font_cfg, const(ImWchar)* glyph_ranges);
const(ImWchar)* ImFontAtlas_GetGlyphRangesDefault(void* self);
void ImFontAtlas_Build(void* self);

// ── ImFontConfig C++ ctor (heap-allocates with defaults) ──────────────────────
void* ImFontConfig_ImFontConfig();
void  ImFontConfig_destroy(void* self);

// ── vibe3d shim functions (from imgui_vibe3d.cpp) ────────────────────────────
ImU32  igVibe3d_Col32(int r, int g, int b, int a);
void   igVibe3d_CheckVersion();
void   igVibe3d_Image(int texId, float w, float h,
                      float u0, float v0, float u1, float v1);
void   igVibe3d_PushFont(ImFont* font);
void*  igVibe3d_GetForegroundDrawList();   // ImDrawList*
void*  igVibe3d_GetBackgroundDrawList();   // ImDrawList*

// ConfigFlagsPtr returns a pointer to the live ConfigFlags field so D can do
// io.ConfigFlags |= X via a @property ref int (compound-assignment on a property).
int*         igVibe3d_IO_ConfigFlagsPtr(void* io);
int          igVibe3d_IO_GetConfigFlags(void* io);
void         igVibe3d_IO_SetConfigFlags(void* io, int v);
bool         igVibe3d_IO_WantCaptureMouse(void* io);
bool         igVibe3d_IO_WantCaptureKeyboard(void* io);
bool         igVibe3d_IO_WantTextInput(void* io);
bool         igVibe3d_IO_KeyCtrl(void* io);
void         igVibe3d_IO_SetIniFilename(void* io, const(char)* s);
void* igVibe3d_IO_Fonts(void* io);    // returns imgui_h.ImFontAtlas*, cast at call site
float        igVibe3d_IO_DisplaySizeX(void* io);
float        igVibe3d_IO_DisplaySizeY(void* io);
void         igVibe3d_IO_AddKeyEvent(void* io, ImGuiKey key, bool down);

float igVibe3d_Style_ItemSpacingX(void* style);
float igVibe3d_Style_ItemSpacingY(void* style);

// ── GetID ─────────────────────────────────────────────────────────────────────
ImGuiID igGetID_Str(const(char)* str_id);

// ── Docking (Phase 0b) ────────────────────────────────────────────────────────
// igDockSpace: creates a dockspace within the current window.
// window_class is optional (pass null); typed as void* to avoid mirroring
// the internal ImGuiWindowClass struct layout.
ImGuiID igDockSpace(ImGuiID dockspace_id, ImVec2_c size,
                    ImGuiDockNodeFlags flags, const(void)* window_class);

// ── DockBuilder (Phase 0b) ────────────────────────────────────────────────────
// DockBuilder is the API for programmatic initial layouts (run once at startup).
// ImGuiDockNode* return values are typed as void* to avoid mirroring the
// internal struct layout; callers cast to imgui_h.ImGuiDockNode*.
void    igDockBuilderRemoveNode(ImGuiID node_id);
ImGuiID igDockBuilderAddNode(ImGuiID node_id, ImGuiDockNodeFlags flags);
void    igDockBuilderSetNodeSize(ImGuiID node_id, ImVec2_c size);
// split_dir is ImGuiDir (int); returns ImGuiID of the new child node at split_dir.
ImGuiID igDockBuilderSplitNode(ImGuiID node_id, ImGuiDir_ split_dir,
                                float size_ratio_for_node_at_dir,
                                ImGuiID* out_id_at_dir,
                                ImGuiID* out_id_at_opposite_dir);
void    igDockBuilderDockWindow(const(char)* window_name, ImGuiID node_id);
void*   igDockBuilderGetNode(ImGuiID node_id);        // returns ImGuiDockNode*
void*   igDockBuilderGetCentralNode(ImGuiID node_id); // returns ImGuiDockNode*
void    igDockBuilderFinish(ImGuiID node_id);

// ── Backends ──────────────────────────────────────────────────────────────────
// These are declared in separate D modules (imgui_impl_sdl2.d / imgui_impl_opengl3.d)
// and linked from the same static archive.
