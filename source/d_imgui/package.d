/// module d_imgui
/// Public ImGui API surface — module-level free functions that mirror the
/// "ImGui::" C++ namespace.
///
/// vibe3d uses:   import ImGui = d_imgui;
/// then calls:    ImGui.Begin(...), ImGui.GetIO(), etc.
///
/// All functions forward to cimgui C bindings declared in imgui_cimgui.d.
///
/// Parameter types for flag arguments (ImGuiWindowFlags, ImGuiChildFlags, …)
/// and enum arguments (ImGuiCol, ImGuiStyleVar, ImGuiMouseButton, …) are
/// declared as plain `int`.  This lets callers pass:
///   - Enum member names:   ImGuiWindowFlags.NoTitleBar
///   - Bitwise combos:      ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.NoResize
///   - Integer literals:    0
/// All of the above are implicitly widened to `int` by D, so `int` parameters
/// accept every form without casts.
module d_imgui;

public import d_imgui.imgui_h;      // types, structs, enums, IM_COL32, IMGUI_CHECKVERSION
public import d_imgui.imconfig;     // ImTextureID alias (project can shadow this file)
public import d_imgui.imgui_demo;   // stub

nothrow @nogc:

// ── cstr helper ───────────────────────────────────────────────────────────────
/// NUL-terminates a D string for passing to cimgui C functions that require
/// a NUL-terminated C string (label, str_id, name, hint, shortcut, format, …).
///
/// Uses a thread-local ring of 8 independently-grown buffers so that multiple
/// cstr() calls within a single expression do not alias each other (e.g.
/// BeginCombo(label, preview) calls cstr(label) and cstr(preview) in the same
/// statement — each lands in its own slot).
///
/// A null string (s.ptr == null) is returned as null, preserving C semantics
/// for optional string parameters such as MenuItem shortcut and popup str_id.
private const(char)* cstr(string s) @trusted
{
    if (s.ptr is null) return null;

    import core.stdc.stdlib : realloc;

    static struct Slot { char* buf = null; size_t cap = 0; }
    static Slot[8] ring;  // thread-local: each thread owns its own ring
    static uint    ridx;

    Slot* slot = &ring[ridx & 7];
    ridx++;

    immutable size_t need = s.length + 1;
    if (slot.cap < need)
    {
        // realloc(null, n) == malloc(n); realloc never throws (@nogc-safe).
        slot.buf = cast(char*) realloc(slot.buf, need);
        slot.cap = need;
    }
    slot.buf[0 .. s.length] = s[];   // copy content (immutable→mutable: @trusted)
    slot.buf[s.length]      = '\0';
    return slot.buf;
}

// ── Context ───────────────────────────────────────────────────────────────────

ImGuiContext* CreateContext(ImFontAtlas* sharedFontAtlas = null) @trusted
{
    return igCreateContext(cast(void*) sharedFontAtlas);
}

void DestroyContext(ImGuiContext* ctx = null) @trusted
{
    igDestroyContext(ctx);
}

// ── Per-frame ─────────────────────────────────────────────────────────────────

void NewFrame() @trusted { igNewFrame(); }
void Render()   @trusted { igRender(); }
ImDrawData* GetDrawData() @trusted { return igGetDrawData(); }

// ── IO / Style ────────────────────────────────────────────────────────────────

/// Returns a reference to the current ImGuiIO (backed by C++ memory).
/// Allows: ImGuiIO* io = &ImGui.GetIO();
ref ImGuiIO GetIO() @trusted
{
    return *cast(ImGuiIO*) igGetIO_Nil();
}

/// Returns a reference to the current ImGuiStyle (backed by C++ memory).
/// Allows: ImGui.GetStyle().ScaleAllSizes(scale);
ref ImGuiStyle GetStyle() @trusted
{
    return *cast(ImGuiStyle*) igGetStyle();
}

void StyleColorsDark() @trusted { igStyleColorsDark(null); }

// ── Windows ───────────────────────────────────────────────────────────────────

bool Begin(string name, bool* p_open = null, int flags = 0) @trusted
{
    return igBegin(cstr(name), p_open, flags);
}

void End() @trusted { igEnd(); }

bool BeginChild(string str_id,
                ImVec2 size = ImVec2(0, 0),
                int childFlags = 0,
                int windowFlags = 0) @trusted
{
    return igBeginChild_Str(cstr(str_id), size.c, childFlags, windowFlags);
}

bool BeginChild(ImGuiID id,
                ImVec2 size = ImVec2(0, 0),
                int childFlags = 0,
                int windowFlags = 0) @trusted
{
    return igBeginChild_ID(id, size.c, childFlags, windowFlags);
}

void EndChild() @trusted { igEndChild(); }

// ── Window utilities ──────────────────────────────────────────────────────────

bool IsWindowAppearing() @trusted { return igIsWindowAppearing(); }

void SetWindowFocus() @trusted             { igSetWindowFocus_Nil(); }
void SetWindowFocus(string name) @trusted  { igSetWindowFocus_Str(cstr(name)); }

void SetNextWindowPos(ImVec2 pos,
                      int cond = 0,
                      ImVec2 pivot = ImVec2(0, 0)) @trusted
{
    igSetNextWindowPos(pos.c, cond, pivot.c);
}

void SetNextWindowSize(ImVec2 size, int cond = 0) @trusted
{
    igSetNextWindowSize(size.c, cond);
}

void SetScrollHereY(float centerYRatio = 0.5f) @trusted
{
    igSetScrollHereY(centerYRatio);
}

// ── Cursor / layout ───────────────────────────────────────────────────────────

ImVec2 GetCursorScreenPos() @trusted { return toImVec2(igGetCursorScreenPos()); }
ImVec2 GetCursorPos()       @trusted { return toImVec2(igGetCursorPos()); }
void   SetCursorPos(ImVec2 pos) @trusted { igSetCursorPos(pos.c); }
ImVec2 GetContentRegionAvail() @trusted { return toImVec2(igGetContentRegionAvail()); }
void   SetNextItemWidth(float w) @trusted { igSetNextItemWidth(w); }
void   SameLine(float offsetFromStartX = 0, float spacing = -1) @trusted
{
    igSameLine(offsetFromStartX, spacing);
}
void Dummy(ImVec2 size) @trusted { igDummy(size.c); }
void Separator() @trusted { igSeparator(); }
void SeparatorText(string label) @trusted { igSeparatorText(cstr(label)); }
void AlignTextToFramePadding() @trusted { igAlignTextToFramePadding(); }
void BeginGroup() @trusted { igBeginGroup(); }
void EndGroup()   @trusted { igEndGroup(); }

// ── Font metrics ──────────────────────────────────────────────────────────────

float GetFontSize()                  @trusted { return igGetFontSize(); }
float GetTextLineHeightWithSpacing() @trusted { return igGetTextLineHeightWithSpacing(); }
float GetFrameHeightWithSpacing()    @trusted { return igGetFrameHeightWithSpacing(); }

// ── ID stack ──────────────────────────────────────────────────────────────────

void PushID(string str_id) @trusted  { igPushID_Str(cstr(str_id)); }
void PushID(int int_id)    @trusted  { igPushID_Int(int_id); }
void PopID()               @trusted  { igPopID(); }

// ── Style ─────────────────────────────────────────────────────────────────────

// idx is int so callers can pass ImGuiCol.Text, ImGuiCol.Text | flag combos, or literals.
void PushStyleColor(int idx, ImU32 col) @trusted
{
    igPushStyleColor_U32(idx, col);
}
void PushStyleColor(int idx, ImVec4 col) @trusted
{
    igPushStyleColor_Vec4(idx, col.c);
}
void PopStyleColor(int count = 1) @trusted { igPopStyleColor(count); }

// idx is int so callers can pass ImGuiStyleVar.WindowPadding etc. without casts.
void PushStyleVar(int idx, float val) @trusted
{
    igPushStyleVar_Float(idx, val);
}
void PushStyleVar(int idx, ImVec2 val) @trusted
{
    igPushStyleVar_Vec2(idx, val.c);
}
void PopStyleVar(int count = 1) @trusted { igPopStyleVar(count); }

// ── Font ──────────────────────────────────────────────────────────────────────

/// PushFont with a single ImFont* arg (size 0 = inherit current size).
void PushFont(ImFont* font) @trusted { igVibe3d_PushFont(font); }
void PopFont()              @trusted { igPopFont(); }

// ── Text ──────────────────────────────────────────────────────────────────────

// Single-string overloads use igTextUnformatted(ptr, ptr+len) — no NUL needed.
void Text(string s)            @trusted { igTextUnformatted(s.ptr, s.ptr + s.length); }
void TextUnformatted(string s) @trusted { igTextUnformatted(s.ptr, s.ptr + s.length); }

// Printf-style Text overloads for integer args (most common in vibe3d).
// igText is a printf-family function; the format string must be NUL-terminated.
void Text(string fmt, int a) @trusted
    { igText(cstr(fmt), a); }
void Text(string fmt, int a, int b) @trusted
    { igText(cstr(fmt), a, b); }
void Text(string fmt, int a, int b, int c) @trusted
    { igText(cstr(fmt), a, b, c); }

// TextColored — single string: igTextColored with "%.*s" avoids NUL requirement.
void TextColored(ImVec4 col, string s) @trusted
{
    igTextColored(col.c, "%.*s", cast(int) s.length, s.ptr);
}
/// TextColored with printf format + one int arg — format is a C string.
void TextColored(ImVec4 col, string fmt, int a) @trusted
    { igTextColored(col.c, cstr(fmt), a); }

// TextDisabled — single string: igTextDisabled with "%.*s" avoids NUL requirement.
void TextDisabled(string s) @trusted
{
    igTextDisabled("%.*s", cast(int) s.length, s.ptr);
}
/// TextDisabled with a runtime string arg passed through "%s" — both fmt and s
/// must be NUL-terminated because they cross the C varargs boundary.
void TextDisabled(string fmt, string s) @trusted
    { igTextDisabled(cstr(fmt), cstr(s)); }
/// TextDisabled with two int args — fmt must be NUL-terminated.
void TextDisabled(string fmt, int a, int b) @trusted
    { igTextDisabled(cstr(fmt), a, b); }

// LabelText — single string: label is a C string; value uses "%.*s" idiom.
void LabelText(string label, string s) @trusted
{
    igLabelText(cstr(label), "%.*s", cast(int) s.length, s.ptr);
}
/// LabelText with printf format + two int args (e.g. "%d/%d").
void LabelText(string label, string fmt, int a, int b) @trusted
    { igLabelText(cstr(label), cstr(fmt), a, b); }

// SetTooltip — single string: igSetTooltip with "%.*s" avoids NUL requirement.
void SetTooltip(string s) @trusted
{
    igSetTooltip("%.*s", cast(int) s.length, s.ptr);
}
/// SetTooltip with printf format + one int arg — format is a C string.
void SetTooltip(string fmt, int a) @trusted { igSetTooltip(cstr(fmt), a); }

// ── Widgets ───────────────────────────────────────────────────────────────────

bool Button(string label, ImVec2 size = ImVec2(0, 0)) @trusted
{
    return igButton(cstr(label), size.c);
}
bool SmallButton(string label) @trusted { return igSmallButton(cstr(label)); }

bool Checkbox(string label, bool* v) @trusted { return igCheckbox(cstr(label), v); }

bool RadioButton(string label, bool active) @trusted
{
    return igRadioButton_Bool(cstr(label), active);
}

bool Selectable(string label, bool selected = false,
                int flags = 0, ImVec2 size = ImVec2(0, 0)) @trusted
{
    return igSelectable_Bool(cstr(label), selected, flags, size.c);
}

bool InputText(string label, char* buf, size_t bufSize,
               int flags = 0) @trusted
{
    return igInputText(cstr(label), buf, bufSize, flags, null, null);
}

/// D slice overload — extracts ptr + length from the char[] automatically.
bool InputText(string label, char[] buf, int flags = 0) @trusted
{
    return igInputText(cstr(label), buf.ptr, buf.length, flags, null, null);
}

bool InputTextWithHint(string label, string hint, char* buf, size_t bufSize,
                       int flags = 0) @trusted
{
    return igInputTextWithHint(cstr(label), cstr(hint), buf, bufSize, flags, null, null);
}

/// D slice overload — extracts ptr + length from the char[] automatically.
bool InputTextWithHint(string label, string hint, char[] buf,
                       int flags = 0) @trusted
{
    return igInputTextWithHint(cstr(label), cstr(hint),
                               buf.ptr, buf.length, flags, null, null);
}

bool SliderFloat(string label, float* v, float vMin, float vMax,
                 string fmt = "%.3f", int flags = 0) @trusted
{
    return igSliderFloat(cstr(label), v, vMin, vMax, cstr(fmt), flags);
}

bool SliderInt(string label, int* v, int vMin, int vMax,
               string fmt = "%d", int flags = 0) @trusted
{
    return igSliderInt(cstr(label), v, vMin, vMax, cstr(fmt), flags);
}

bool DragFloat(string label, float* v, float vSpeed = 1.0f,
               float vMin = 0, float vMax = 0,
               string fmt = "%.3f", int flags = 0) @trusted
{
    return igDragFloat(cstr(label), v, vSpeed, vMin, vMax, cstr(fmt), flags);
}

bool DragInt(string label, int* v, float vSpeed = 1.0f,
             int vMin = 0, int vMax = 0,
             string fmt = "%d", int flags = 0) @trusted
{
    return igDragInt(cstr(label), v, vSpeed, vMin, vMax, cstr(fmt), flags);
}

bool CollapsingHeader(string label, int flags = 0) @trusted
{
    return igCollapsingHeader_TreeNodeFlags(cstr(label), flags);
}

void ProgressBar(float fraction, ImVec2 sizeArg = ImVec2(-float.min_normal, 0),
                 string overlay = null) @trusted
{
    // overlay may be null (cimgui draws no text overlay when null).
    igProgressBar(fraction, sizeArg.c, cstr(overlay));
}

// ── Combo ─────────────────────────────────────────────────────────────────────

bool BeginCombo(string label, string previewValue, int flags = 0) @trusted
{
    return igBeginCombo(cstr(label), cstr(previewValue), flags);
}
void EndCombo() @trusted { igEndCombo(); }

bool Combo(string label, int* currentItem,
           const(char*)[] items, int popupMaxHeightInItems = -1) @trusted
{
    return igCombo_Str_arr(cstr(label), currentItem,
                           items.ptr, cast(int) items.length,
                           popupMaxHeightInItems);
}

// ── Menus ─────────────────────────────────────────────────────────────────────

bool BeginMenu(string label, bool enabled = true) @trusted
{
    return igBeginMenu(cstr(label), enabled);
}
void EndMenu() @trusted { igEndMenu(); }

bool MenuItem(string label, string shortcut = null,
              bool selected = false, bool enabled = true) @trusted
{
    // shortcut defaults to null → cstr(null) returns null (no shortcut displayed).
    return igMenuItem_Bool(cstr(label), cstr(shortcut), selected, enabled);
}

// ── Popups ────────────────────────────────────────────────────────────────────

bool BeginPopup(string strId, int flags = 0) @trusted
{
    return igBeginPopup(cstr(strId), flags);
}

bool BeginPopupModal(string name, bool* p_open = null, int flags = 0) @trusted
{
    return igBeginPopupModal(cstr(name), p_open, flags);
}

void EndPopup() @trusted { igEndPopup(); }

void OpenPopup(string strId, int popupFlags = 0) @trusted
{
    igOpenPopup_Str(cstr(strId), popupFlags);
}

bool BeginPopupContextItem(string strId = null,
                            int popupFlags = ImGuiPopupFlags.MouseButtonRight) @trusted
{
    // strId defaults to null → cstr(null) returns null (cimgui uses last item id).
    return igBeginPopupContextItem(cstr(strId), popupFlags);
}

bool BeginPopupContextWindow(string strId = null,
                              int popupFlags = ImGuiPopupFlags.MouseButtonRight) @trusted
{
    return igBeginPopupContextWindow(cstr(strId), popupFlags);
}

void CloseCurrentPopup() @trusted { igCloseCurrentPopup(); }

// ── Disabled ──────────────────────────────────────────────────────────────────

void BeginDisabled(bool disabled = true) @trusted { igBeginDisabled(disabled); }
void EndDisabled() @trusted { igEndDisabled(); }

// ── Item queries ──────────────────────────────────────────────────────────────

bool IsItemHovered(int flags = 0) @trusted
{
    return igIsItemHovered(flags);
}
bool IsItemActive()               @trusted { return igIsItemActive(); }
bool IsItemDeactivated()          @trusted { return igIsItemDeactivated(); }
bool IsItemDeactivatedAfterEdit() @trusted { return igIsItemDeactivatedAfterEdit(); }
bool IsAnyItemActive()            @trusted { return igIsAnyItemActive(); }
ImVec2 GetItemRectMin()           @trusted { return toImVec2(igGetItemRectMin()); }
ImVec2 GetItemRectMax()           @trusted { return toImVec2(igGetItemRectMax()); }
void SetItemDefaultFocus()        @trusted { igSetItemDefaultFocus(); }

// ── Text utilities ────────────────────────────────────────────────────────────

// CalcTextSize uses igCalcTextSize(ptr, ptr+len) — no NUL needed (correct as-is).
ImVec2 CalcTextSize(string text,
                    bool hideTextAfterDoubleHash = false,
                    float wrapWidth = -1) @trusted
{
    return toImVec2(igCalcTextSize(text.ptr, text.ptr + text.length,
                                   hideTextAfterDoubleHash, wrapWidth));
}

// ── Mouse / keyboard ─────────────────────────────────────────────────────────

bool IsMouseDoubleClicked(int button) @trusted
{
    return igIsMouseDoubleClicked_Nil(button);
}

bool IsKeyPressed(int key, bool repeat = true) @trusted
{
    return igIsKeyPressed_Bool(key, repeat);
}

ImVec2 GetMouseDragDelta(int button = 0, float lockThreshold = -1) @trusted
{
    return toImVec2(igGetMouseDragDelta(button, lockThreshold));
}

void ResetMouseDragDelta(int button = 0) @trusted
{
    igResetMouseDragDelta(button);
}

void SetMouseCursor(int cursorType) @trusted
{
    igSetMouseCursor(cursorType);
}

// ── Drag & drop ───────────────────────────────────────────────────────────────

bool BeginDragDropSource(int flags = 0) @trusted
{
    return igBeginDragDropSource(flags);
}
void EndDragDropSource() @trusted { igEndDragDropSource(); }

bool BeginDragDropTarget() @trusted { return igBeginDragDropTarget(); }
void EndDragDropTarget()   @trusted { igEndDragDropTarget(); }

bool SetDragDropPayload(string type_, const(void)* data, size_t sz,
                        int cond = 0) @trusted
{
    return igSetDragDropPayload(cstr(type_), data, sz, cond);
}

const(ImGuiPayload)* AcceptDragDropPayload(string type_, int flags = 0) @trusted
{
    return cast(const(ImGuiPayload)*) igAcceptDragDropPayload(cstr(type_), flags);
}

// ── Image ─────────────────────────────────────────────────────────────────────

void Image(ImTextureID texId, ImVec2 size,
           ImVec2 uv0 = ImVec2(0, 0), ImVec2 uv1 = ImVec2(1, 1)) @trusted
{
    igVibe3d_Image(cast(int) texId, size.x, size.y,
                   uv0.x, uv0.y, uv1.x, uv1.y);
}

// ── Draw lists ────────────────────────────────────────────────────────────────

ImDrawList* GetWindowDrawList() @trusted
{
    return cast(ImDrawList*) igGetWindowDrawList();
}

ImDrawList* GetForegroundDrawList() @trusted
{
    return cast(ImDrawList*) igVibe3d_GetForegroundDrawList();
}

ImDrawList* GetBackgroundDrawList() @trusted
{
    return cast(ImDrawList*) igVibe3d_GetBackgroundDrawList();
}

// ── Clipboard ─────────────────────────────────────────────────────────────────

void SetClipboardText(string text) @trusted { igSetClipboardText(cstr(text)); }

// ── Keyboard focus ────────────────────────────────────────────────────────────

void SetKeyboardFocusHere(int offset = 0) @trusted
{
    igSetKeyboardFocusHere(offset);
}

// ── Window ID ─────────────────────────────────────────────────────────────────

/// Returns a stable ID hash for a string label in the current ID stack.
/// Used to obtain the dockspace ID:  ImGuiID id = ImGui.GetID("MainDockSpace");
ImGuiID GetID(string str_id) @trusted
{
    return igGetID_Str(cstr(str_id));
}

// ── Docking (Phase 0b) ────────────────────────────────────────────────────────

/// Create a dockspace inside the current window.
/// size = (0,0) fills the entire remaining window content area.
/// flags = ImGuiDockNodeFlags bitmask (e.g. PassthruCentralNode).
/// Returns the dockspace's root node ImGuiID.
ImGuiID DockSpace(ImGuiID dockspaceId,
                  ImVec2  size  = ImVec2(0, 0),
                  int     flags = 0) @trusted
{
    return igDockSpace(dockspaceId, size.c, flags, null);
}

// ── DockBuilder (Phase 0b) ────────────────────────────────────────────────────
// These functions are for programmatic initial layout setup (run once at startup).

/// Remove all nodes rooted at nodeId, clearing any persisted layout.
void DockBuilderRemoveNode(ImGuiID nodeId) @trusted
{
    igDockBuilderRemoveNode(nodeId);
}

/// Add a new root docking node (or reset nodeId to a fresh node).
/// flags = ImGuiDockNodeFlags bitmask; pass 0 for a plain root.
/// Returns nodeId (convenience — same value passed in).
ImGuiID DockBuilderAddNode(ImGuiID nodeId, int flags = 0) @trusted
{
    return igDockBuilderAddNode(nodeId, flags);
}

/// Set the explicit pixel size of a dock node (call before splitting).
void DockBuilderSetNodeSize(ImGuiID nodeId, ImVec2 size) @trusted
{
    igDockBuilderSetNodeSize(nodeId, size.c);
}

/// Split nodeId along splitDir.
/// sizeRatioForDir — fraction of nodeId's size assigned to the new child
/// node in the splitDir direction.
/// outIdAtDir      — receives the new child node ID in splitDir.
/// outIdAtOppDir   — receives the remaining child node ID (opposite side).
/// Returns the new child node ID at splitDir (same as *outIdAtDir).
ImGuiID DockBuilderSplitNode(ImGuiID  nodeId,
                              int      splitDir,
                              float    sizeRatioForDir,
                              ImGuiID* outIdAtDir,
                              ImGuiID* outIdAtOppDir) @trusted
{
    return igDockBuilderSplitNode(nodeId, splitDir, sizeRatioForDir,
                                  outIdAtDir, outIdAtOppDir);
}

/// Assign window windowName to dock node nodeId.
/// Call this before DockBuilderFinish.
void DockBuilderDockWindow(string windowName, ImGuiID nodeId) @trusted
{
    igDockBuilderDockWindow(cstr(windowName), nodeId);
}

/// Look up a dock node by ID (returns null if not found).
ImGuiDockNode* DockBuilderGetNode(ImGuiID nodeId) @trusted
{
    return cast(ImGuiDockNode*) igDockBuilderGetNode(nodeId);
}

/// Look up the central (unoccupied) node of a dockspace (returns null if none).
ImGuiDockNode* DockBuilderGetCentralNode(ImGuiID nodeId) @trusted
{
    return cast(ImGuiDockNode*) igDockBuilderGetCentralNode(nodeId);
}

/// Finalize the DockBuilder layout — must be called after all split/dock ops.
void DockBuilderFinish(ImGuiID nodeId) @trusted
{
    igDockBuilderFinish(nodeId);
}
