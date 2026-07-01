/// D types, enums, and utility functions for the cimgui 1.92.8 docking shim.
/// Mirrors the public surface of imgui.h needed by vibe3d.
///
/// ImGuiIO and ImGuiStyle are intentionally opaque (no field layout) — their
/// data is accessed through igVibe3d_IO_* / igVibe3d_Style_* C wrappers in
/// imgui_vibe3d.cpp, so this file never needs updating when imgui's struct
/// layout changes.
module d_imgui.imgui_h;

public import d_imgui.imgui_cimgui;

// ── Basic types ───────────────────────────────────────────────────────────────
// ImTextureID and ImWchar come from the project-local d_imgui.imconfig.

// ── Value types ───────────────────────────────────────────────────────────────

struct ImVec2
{
    float x = 0, y = 0;
    this(float x, float y) @safe pure nothrow @nogc { this.x = x; this.y = y; }
    ImVec2_c c() const @safe nothrow @nogc { return ImVec2_c(x, y); }
    // Arithmetic helpers used in vibe3d
    ImVec2 opBinary(string op)(ImVec2 rhs) const @safe nothrow @nogc
        if (op == "+" || op == "-")
    {
        static if (op == "+") return ImVec2(x + rhs.x, y + rhs.y);
        else                   return ImVec2(x - rhs.x, y - rhs.y);
    }
    ImVec2 opBinary(string op)(float s) const @safe nothrow @nogc
        if (op == "*")
    {
        return ImVec2(x * s, y * s);
    }
}

struct ImVec4
{
    float x = 0, y = 0, z = 0, w = 0;
    this(float x, float y, float z, float w) @safe pure nothrow @nogc
    { this.x = x; this.y = y; this.z = z; this.w = w; }
    ImVec4_c c() const @safe nothrow @nogc { return ImVec4_c(x, y, z, w); }
}

// Convenience conversion from cimgui value types to D value types.
ImVec2 toImVec2(ImVec2_c v) @safe nothrow @nogc { return ImVec2(v.x, v.y); }
ImVec4 toImVec4(ImVec4_c v) @safe nothrow @nogc { return ImVec4(v.x, v.y, v.z, v.w); }

// ── ImFontConfig ──────────────────────────────────────────────────────────────
// Layout must exactly match C++ ImFontConfig on x86-64 (verified offset-by-offset
// against imgui.h 1.92.8).  Field defaults match C++ constructor defaults.
//
//   offset  size  field
//        0    40  Name[40]
//       40     8  FontData
//       48     4  FontDataSize
//       52     1  FontDataOwnedByAtlas (default true)
//       53     1  MergeMode
//       54     1  PixelSnapH
//       55     1  OversampleH (ImS8, default 0 = auto)
//       56     1  OversampleV (ImS8, default 0 = auto)
//       57     1  [pad]
//       58     2  EllipsisChar (ImWchar)
//       60     4  SizePixels
//       64     8  GlyphRanges*
//       72     8  GlyphExcludeRanges*
//       80     8  GlyphOffset (ImVec2)
//       88     4  GlyphMinAdvanceX
//       92     4  GlyphMaxAdvanceX (default FLT_MAX)
//       96     4  GlyphExtraAdvanceX
//      100     4  FontNo
//      104     4  FontLoaderFlags
//      108     4  RasterizerMultiply (default 1.0f)
//      112     4  RasterizerDensity  (default 1.0f)
//      116     4  ExtraSizeScale     (default 1.0f)
//      120     4  Flags (ImFontFlags = int)
//      124     4  [pad]
//      128     8  DstFont*
//      136     8  FontLoader* (const ImFontLoader*)
//      144     8  FontLoaderData*
//      152     1  PixelSnapV (default true, obsolete)
//   153-159     7  [pad]
//      160       total
struct ImFontConfig
{
    char[40]  Name                  = '\0';
    void*     FontData              = null;
    int       FontDataSize          = 0;
    bool      FontDataOwnedByAtlas  = true;
    bool      MergeMode             = false;
    bool      PixelSnapH            = false;
    byte      OversampleH           = 0;
    byte      OversampleV           = 0;
    // 1 byte padding here (D aligns ushort to 2)
    ushort    EllipsisChar          = 0;
    float     SizePixels            = 0.0f;
    const(ushort)* GlyphRanges      = null;
    const(ushort)* GlyphExcludeRanges = null;
    ImVec2    GlyphOffset           = ImVec2(0, 0);
    float     GlyphMinAdvanceX      = 0.0f;
    float     GlyphMaxAdvanceX      = float.max;
    float     GlyphExtraAdvanceX    = 0.0f;
    uint      FontNo                = 0;
    uint      FontLoaderFlags       = 0;
    float     RasterizerMultiply    = 1.0f;
    float     RasterizerDensity     = 1.0f;
    float     ExtraSizeScale        = 1.0f;
    int       Flags                 = 0;      // ImFontFlags — 4 bytes pad after (ptr alignment)
    ImFont*   DstFont               = null;
    void*     FontLoader            = null;   // const ImFontLoader*
    void*     FontLoaderData        = null;
    bool      PixelSnapV            = true;   // 7 bytes pad to total 160
    // No explicit pad fields needed — D naturally aligns to 8 after PixelSnapV
    // to reach 160 bytes total; verified by static assert below.

    // Convenience constructor — body intentionally empty; field defaults do the work.
    // app.d: ImFontConfig fontCfg = ImFontConfig(false);
    this(bool /*dummy*/) @safe pure nothrow @nogc { }
}
static assert(ImFontConfig.sizeof == 160,
    "ImFontConfig size mismatch vs C++ imgui.h 1.92.8 on x86-64");

// ── ImDrawList ────────────────────────────────────────────────────────────────
// Opaque wrapper: methods call C cimgui functions with a 'void* self' cast.
// vibe3d always holds ImDrawList through a pointer, never by value.
struct ImDrawList
{
    nothrow @nogc:

    void AddLine(ImVec2 p1, ImVec2 p2, ImU32 col, float thickness = 1.0f) @trusted
    {
        ImDrawList_AddLine(&this, p1.c, p2.c, col, thickness);
    }
    void AddText(ImVec2 pos, ImU32 col,
                 const(char)* textBegin, const(char)* textEnd = null) @trusted
    {
        ImDrawList_AddText_Vec2(&this, pos.c, col, textBegin, textEnd);
    }
    /// D string overload — passes ptr + end pointer (no null-terminator needed).
    void AddText(ImVec2 pos, ImU32 col, string text) @trusted
    {
        ImDrawList_AddText_Vec2(&this, pos.c, col, text.ptr, text.ptr + text.length);
    }
    void AddRectFilled(ImVec2 pMin, ImVec2 pMax, ImU32 col,
                       float rounding = 0.0f, int flags = 0) @trusted
    {
        ImDrawList_AddRectFilled(&this, pMin.c, pMax.c, col, rounding, flags);
    }
    // D method uses C++ API order (flags, then thickness).
    // cimgui 1.92.8 wraps with thickness BEFORE flags — we swap at the call.
    void AddRect(ImVec2 pMin, ImVec2 pMax, ImU32 col,
                 float rounding = 0.0f, int flags = 0, float thickness = 1.0f) @trusted
    {
        ImDrawList_AddRect(&this, pMin.c, pMax.c, col, rounding, thickness, flags);
    }
    void AddQuadFilled(ImVec2 p1, ImVec2 p2, ImVec2 p3, ImVec2 p4, ImU32 col) @trusted
    {
        ImDrawList_AddQuadFilled(&this, p1.c, p2.c, p3.c, p4.c, col);
    }
    void AddCircle(ImVec2 center, float radius, ImU32 col,
                   int numSegments = 0, float thickness = 1.0f) @trusted
    {
        ImDrawList_AddCircle(&this, center.c, radius, col, numSegments, thickness);
    }
    void AddCircleFilled(ImVec2 center, float radius, ImU32 col,
                         int numSegments = 0) @trusted
    {
        ImDrawList_AddCircleFilled(&this, center.c, radius, col, numSegments);
    }
    void AddTriangleFilled(ImVec2 p1, ImVec2 p2, ImVec2 p3, ImU32 col) @trusted
    {
        ImDrawList_AddTriangleFilled(&this, p1.c, p2.c, p3.c, col);
    }
    // D method uses C++ API order: (col, flags, thickness).
    // cimgui 1.92.8 wraps with thickness BEFORE flags — we swap at the call.
    void AddPolyline(const(ImVec2)* pts, int n, ImU32 col,
                     int flags, float thickness) @trusted
    {
        ImDrawList_AddPolyline(&this, cast(const(ImVec2_c)*) pts,
                               n, col, thickness, flags);
    }
    void AddConvexPolyFilled(const(ImVec2)* pts, int n, ImU32 col) @trusted
    {
        ImDrawList_AddConvexPolyFilled(&this, cast(const(ImVec2_c)*) pts, n, col);
    }
    void PathFillConvex(ImU32 col) @trusted { ImDrawList_PathFillConvex(&this, col); }
    void AddBezierCubic(ImVec2 p1, ImVec2 p2, ImVec2 p3, ImVec2 p4,
                        ImU32 col, float thickness, int numSegments = 0) @trusted
    {
        ImDrawList_AddBezierCubic(&this, p1.c, p2.c, p3.c, p4.c,
                                  col, thickness, numSegments);
    }
    void PathLineTo(ImVec2 pos) @trusted
    {
        ImDrawList_PathLineTo(&this, pos.c);
    }
    // D method uses C++ API order: (col, flags, thickness).
    // cimgui 1.92.8 wraps with thickness BEFORE flags — we swap at the call.
    void PathStroke(ImU32 col, int flags, float thickness = 1.0f) @trusted
    {
        ImDrawList_PathStroke(&this, col, thickness, flags);
    }
    void PathClear() @trusted { ImDrawList_PathClear(&this); }
    void PushClipRect(ImVec2 clipMin, ImVec2 clipMax,
                      bool intersectWithCurrent = false) @trusted
    {
        ImDrawList_PushClipRect(&this, clipMin.c, clipMax.c, intersectWithCurrent);
    }
    void PopClipRect() @trusted { ImDrawList_PopClipRect(&this); }
}

// ── ImFontAtlas ───────────────────────────────────────────────────────────────
struct ImFontAtlas
{
    nothrow @nogc:

    ImFont* AddFontFromMemoryTTF(ubyte[] data, float sizePixels,
                                  const(ImFontConfig)* cfg = null,
                                  const(ushort)* glyphRanges = null) @trusted
    {
        return ImFontAtlas_AddFontFromMemoryTTF(
            cast(void*)&this, data.ptr, cast(int) data.length,
            sizePixels, cfg, glyphRanges);
    }
    const(ushort)* GetGlyphRangesDefault() @trusted
    {
        return ImFontAtlas_GetGlyphRangesDefault(cast(void*)&this);
    }
    void Build() @trusted { ImFontAtlas_Build(cast(void*)&this); }
}

// ── ImGuiIO (opaque) ──────────────────────────────────────────────────────────
// All field access goes through igVibe3d_IO_* C wrappers.
struct ImGuiIO
{
    nothrow @nogc:

    // ref property: allows compound assignment (io.ConfigFlags |= X).
    @property ref int ConfigFlags() @trusted
    { return *igVibe3d_IO_ConfigFlagsPtr(cast(void*)&this); }

    @property bool WantCaptureMouse() const @trusted
    { return igVibe3d_IO_WantCaptureMouse(cast(void*)&this); }
    @property bool WantCaptureKeyboard() const @trusted
    { return igVibe3d_IO_WantCaptureKeyboard(cast(void*)&this); }
    @property bool WantTextInput() const @trusted
    { return igVibe3d_IO_WantTextInput(cast(void*)&this); }
    @property bool KeyCtrl() const @trusted
    { return igVibe3d_IO_KeyCtrl(cast(void*)&this); }

    @property void IniFilename(const(char)* s) @trusted
    { igVibe3d_IO_SetIniFilename(cast(void*)&this, s); }

    @property ImFontAtlas* Fonts() @trusted
    { return cast(ImFontAtlas*) igVibe3d_IO_Fonts(cast(void*)&this); }

    @property ImVec2 DisplaySize() const @trusted
    {
        return ImVec2(igVibe3d_IO_DisplaySizeX(cast(void*)&this),
                      igVibe3d_IO_DisplaySizeY(cast(void*)&this));
    }

    void AddKeyEvent(ImGuiKey key, bool down) @trusted
    { igVibe3d_IO_AddKeyEvent(cast(void*)&this, key, down); }
}

// ── ImGuiStyle (opaque) ───────────────────────────────────────────────────────
struct ImGuiStyle
{
    nothrow @nogc:

    @property ImVec2 ItemSpacing() const @trusted
    {
        return ImVec2(igVibe3d_Style_ItemSpacingX(cast(void*)&this),
                      igVibe3d_Style_ItemSpacingY(cast(void*)&this));
    }
    void ScaleAllSizes(float scale) @trusted
    { ImGuiStyle_ScaleAllSizes(cast(void*)&this, scale); }
}

// ── ImGuiPayload ──────────────────────────────────────────────────────────────
struct ImGuiPayload
{
    void* Data;
    int   DataSize;
    // Remaining fields (source/delivery tracking) are not used by vibe3d directly.
    // Pad to actual C++ size to be safe if ever allocated on D stack (we never do).
    private ubyte[56] _pad;
    bool Preview;
    bool Delivery;
}

// ── Free utility functions ────────────────────────────────────────────────────

/// IMGUI_CHECKVERSION() macro equivalent.
void IMGUI_CHECKVERSION() @trusted nothrow @nogc
{
    igVibe3d_CheckVersion();
}

/// IM_COL32(R,G,B,A) macro equivalent — pure D bit-packing, evaluable at compile time.
/// Mirrors the C++ macro: (A<<24)|(B<<16)|(G<<8)|R
ImU32 IM_COL32(int r, int g, int b, int a) pure @safe nothrow @nogc
{
    return (cast(ImU32) a << 24) | (cast(ImU32) b << 16) |
           (cast(ImU32) g <<  8) |  cast(ImU32) r;
}

// ── Draw flags ────────────────────────────────────────────────────────────────

enum ImDrawFlags : int
{
    None                     = 0,
    Closed                   = 1 << 9,
    RoundCornersTopLeft      = 1 << 4,
    RoundCornersTopRight     = 1 << 5,
    RoundCornersBottomLeft   = 1 << 6,
    RoundCornersBottomRight  = 1 << 7,
    RoundCornersNone         = 1 << 8,
    RoundCornersTop          = RoundCornersTopLeft | RoundCornersTopRight,
    RoundCornersBottom       = RoundCornersBottomLeft | RoundCornersBottomRight,
    RoundCornersLeft         = RoundCornersBottomLeft | RoundCornersTopLeft,
    RoundCornersRight        = RoundCornersBottomRight | RoundCornersTopRight,
    RoundCornersAll          = RoundCornersTopLeft | RoundCornersTopRight |
                               RoundCornersBottomLeft | RoundCornersBottomRight,
}

// ── Enums ─────────────────────────────────────────────────────────────────────

enum ImGuiWindowFlags : int
{
    None                    = 0,
    NoTitleBar              = 1 << 0,
    NoResize                = 1 << 1,
    NoMove                  = 1 << 2,
    NoScrollbar             = 1 << 3,
    NoScrollWithMouse       = 1 << 4,
    NoCollapse              = 1 << 5,
    AlwaysAutoResize        = 1 << 6,
    NoBackground            = 1 << 7,
    NoSavedSettings         = 1 << 8,
    NoMouseInputs           = 1 << 9,
    MenuBar                 = 1 << 10,
    HorizontalScrollbar     = 1 << 11,
    NoFocusOnAppearing      = 1 << 12,
    NoBringToFrontOnFocus   = 1 << 13,
    AlwaysVerticalScrollbar = 1 << 14,
    AlwaysHorizontalScrollbar = 1 << 15,
    NoNavInputs             = 1 << 16,
    NoNavFocus              = 1 << 17,
    UnsavedDocument         = 1 << 18,
    NoDocking               = 1 << 19,
    NoNav                   = NoNavInputs | NoNavFocus,
    NoDecoration            = NoTitleBar | NoResize | NoScrollbar | NoCollapse,
    NoInputs                = NoMouseInputs | NoNavInputs | NoNavFocus,
}

enum ImGuiChildFlags : int
{
    None                    = 0,
    Borders                 = 1 << 0,
    AlwaysUseWindowPadding  = 1 << 1,
    ResizeX                 = 1 << 2,
    ResizeY                 = 1 << 3,
    AutoResizeX             = 1 << 4,
    AutoResizeY             = 1 << 5,
    AlwaysAutoResize        = 1 << 6,
    FrameStyle              = 1 << 7,
    NavFlattened            = 1 << 8,
}

enum ImGuiCol : int
{
    Text                  = 0,
    TextDisabled          = 1,
    WindowBg              = 2,
    ChildBg               = 3,
    PopupBg               = 4,
    Border                = 5,
    BorderShadow          = 6,
    FrameBg               = 7,
    FrameBgHovered        = 8,
    FrameBgActive         = 9,
    TitleBg               = 10,
    TitleBgActive         = 11,
    TitleBgCollapsed      = 12,
    MenuBarBg             = 13,
    ScrollbarBg           = 14,
    ScrollbarGrab         = 15,
    ScrollbarGrabHovered  = 16,
    ScrollbarGrabActive   = 17,
    CheckMark             = 18,
    CheckboxSelectedBg    = 19, // NEW in 1.92.x
    SliderGrab            = 20,
    SliderGrabActive      = 21,
    Button                = 22,
    ButtonHovered         = 23,
    ButtonActive          = 24,
    Header                = 25,
    HeaderHovered         = 26,
    HeaderActive          = 27,
    Separator             = 28,
    SeparatorHovered      = 29,
    SeparatorActive       = 30,
    ResizeGrip            = 31,
    ResizeGripHovered     = 32,
    ResizeGripActive      = 33,
    InputTextCursor       = 34,
    TabHovered            = 35,
    Tab                   = 36,
    TabSelected           = 37,
    TabSelectedOverline   = 38,
    TabDimmed             = 39,
    TabDimmedSelected     = 40,
    TabDimmedSelectedOverline = 41,
    DockingPreview        = 42,
    DockingEmptyBg        = 43,
    PlotLines             = 44,
    PlotLinesHovered      = 45,
    PlotHistogram         = 46,
    PlotHistogramHovered  = 47,
    TableHeaderBg         = 48,
    TableBorderStrong     = 49,
    TableBorderLight      = 50,
    TableRowBg            = 51,
    TableRowBgAlt         = 52,
    TextLink              = 53,
    TextSelectedBg        = 54,
    TreeLines             = 55,
    DragDropTarget        = 56,
    DragDropTargetBg      = 57,
    UnsavedMarker         = 58,
    NavCursor             = 59,
    NavWindowingHighlight = 60,
    NavWindowingDimBg     = 61,
    ModalWindowDimBg      = 62,
    COUNT                 = 63,
}

enum ImGuiStyleVar : int
{
    Alpha                       = 0,
    DisabledAlpha               = 1,
    WindowPadding               = 2,
    WindowRounding              = 3,
    WindowBorderSize            = 4,
    WindowMinSize               = 5,
    WindowTitleAlign            = 6,
    ChildRounding               = 7,
    ChildBorderSize             = 8,
    PopupRounding               = 9,
    PopupBorderSize             = 10,
    FramePadding                = 11,
    FrameRounding               = 12,
    FrameBorderSize             = 13,
    ItemSpacing                 = 14,
    ItemInnerSpacing            = 15,
    IndentSpacing               = 16,
    CellPadding                 = 17,
    ScrollbarSize               = 18,
    ScrollbarRounding           = 19,
    ScrollbarPadding            = 20,
    GrabMinSize                 = 21,
    GrabRounding                = 22,
    ImageRounding               = 23,
    ImageBorderSize             = 24,
    TabRounding                 = 25,
    TabBorderSize               = 26,
    TabMinWidthBase             = 27,
    TabMinWidthShrink           = 28,
    TabBarBorderSize            = 29,
    TabBarOverlineSize          = 30,
    TableAngledHeadersAngle     = 31,
    TableAngledHeadersTextAlign = 32,
    TreeLinesSize               = 33,
    TreeLinesRounding           = 34,
    DragDropTargetRounding      = 35,
    ButtonTextAlign             = 36,
    SelectableTextAlign         = 37,
    SeparatorSize               = 38,
    SeparatorTextBorderSize     = 39,
    SeparatorTextAlign          = 40,
    SeparatorTextPadding        = 41,
    DockingSeparatorSize        = 42,
    COUNT                       = 43,
}

enum ImGuiCond : int
{
    None         = 0,
    Always       = 1 << 0,
    Once         = 1 << 1,
    FirstUseEver = 1 << 2,
    Appearing    = 1 << 3,
}

enum ImGuiConfigFlags : int
{
    None                  = 0,
    NavEnableKeyboard     = 1 << 0,
    NavEnableGamepad      = 1 << 1,
    NoMouse               = 1 << 4,
    NoMouseCursorChange   = 1 << 5,
    NoKeyboard            = 1 << 7,
    IsSRGB                = 1 << 20,
    IsTouchScreen         = 1 << 21,
}

enum ImGuiInputTextFlags : int
{
    None                  = 0,
    CharsDecimal          = 1 << 0,
    CharsHexadecimal      = 1 << 1,
    CharsScientific       = 1 << 2,
    CharsUppercase        = 1 << 3,
    CharsNoBlank          = 1 << 4,
    AllowTabInput         = 1 << 5,
    EnterReturnsTrue      = 1 << 6,
    EscapeClearsAll       = 1 << 7,
    CtrlEnterForNewLine   = 1 << 8,
    ReadOnly              = 1 << 14,
    Password              = 1 << 15,
    AlwaysOverwrite       = 1 << 16,
    AutoSelectAll         = 1 << 17,
    ParseEmptyRefVal      = 1 << 18,
    DisplayEmptyRefVal    = 1 << 19,
    NoHorizontalScroll    = 1 << 20,
    NoUndoRedo            = 1 << 21,
    CallbackCompletion    = 1 << 22,
    CallbackHistory       = 1 << 23,
    CallbackAlways        = 1 << 24,
    CallbackCharFilter    = 1 << 25,
    CallbackResize        = 1 << 26,
    CallbackEdit          = 1 << 27,
}

enum ImGuiSliderFlags : int
{
    None            = 0,
    Logarithmic     = 1 << 5,
    NoRoundToFormat = 1 << 6,
    NoInput         = 1 << 7,
    WrapAround      = 1 << 8,
    ClampOnInput    = 1 << 9,
    ClampZeroRange  = 1 << 10,
    NoSpeedTweaks   = 1 << 11,
    AlwaysClamp     = ClampOnInput | ClampZeroRange,
}

enum ImGuiKey : int
{
    None      = 0,
    Tab       = 512,
    Delete    = 522,
    Backspace = 523,
    Space     = 524,
    Enter     = 525,
    Escape    = 526,
    Y         = 570,
    Z         = 571,
    COUNT     = 666,
}

enum ImGuiMouseButton : int
{
    Left   = 0,
    Right  = 1,
    Middle = 2,
    COUNT  = 5,
}

enum ImGuiMouseCursor : int
{
    None       = -1,
    Arrow      = 0,
    TextInput  = 1,
    ResizeAll  = 2,
    ResizeNS   = 3,
    ResizeEW   = 4,
    ResizeNESW = 5,
    ResizeNWSE = 6,
    Hand       = 7,
    Wait       = 8,
    Progress   = 9,
    NotAllowed = 10,
    COUNT      = 11,
}

enum ImGuiPopupFlags : int
{
    None                    = 0,
    MouseButtonLeft         = 0,
    MouseButtonRight        = 1,
    MouseButtonMiddle       = 2,
    MouseButtonMask_        = 0x1F,
    NoOpenOverExistingPopup = 1 << 5,
    NoOpenOverItems         = 1 << 6,
    AnyPopupId              = 1 << 7,
    AnyPopupLevel           = 1 << 8,
    AnyPopup                = AnyPopupId | AnyPopupLevel,
}

enum ImGuiSelectableFlags : int
{
    None             = 0,
    NoAutoClosePopups = 1 << 0,  // was DontClosePopups
    SpanAllColumns   = 1 << 1,
    AllowDoubleClick = 1 << 2,
    Disabled         = 1 << 3,
    AllowOverlap     = 1 << 4,
    Highlight        = 1 << 6,
    // Backwards compat alias
    AllowItemOverlap = 1 << 4,
}

enum ImGuiHoveredFlags : int
{
    None                          = 0,
    ChildWindows                  = 1 << 0,
    RootWindow                    = 1 << 1,
    AnyWindow                     = 1 << 2,
    NoPopupHierarchy              = 1 << 3,
    DockHierarchy                 = 1 << 4,
    AllowWhenBlockedByPopup       = 1 << 5,
    AllowWhenBlockedByActiveItem  = 1 << 7,
    AllowWhenOverlappedByItem     = 1 << 8,
    AllowWhenOverlappedByWindow   = 1 << 9,
    AllowWhenDisabled             = 1 << 10,
    NoNavOverride                 = 1 << 11,
    AllowWhenOverlapped           = AllowWhenOverlappedByItem | AllowWhenOverlappedByWindow,
    RectOnly                      = AllowWhenBlockedByPopup | AllowWhenBlockedByActiveItem | AllowWhenOverlapped,
    RootAndChildWindows           = RootWindow | ChildWindows,
    ForTooltip                    = 1 << 12,
    Stationary                    = 1 << 13,
    DelayNone                     = 1 << 14,
    DelayShort                    = 1 << 15,
    DelayNormal                   = 1 << 16,
    NoSharedDelay                 = 1 << 17,
}

enum ImGuiFocusedFlags : int
{
    None                  = 0,
    ChildWindows          = 1 << 0,
    RootWindow            = 1 << 1,
    AnyWindow             = 1 << 2,
    NoPopupHierarchy      = 1 << 3,
    DockHierarchy         = 1 << 4,
    RootAndChildWindows   = RootWindow | ChildWindows,
}

enum ImGuiDragDropFlags : int
{
    None                        = 0,
    SourceNoPreviewTooltip      = 1 << 0,
    SourceNoDisableHover        = 1 << 1,
    SourceNoHoldToOpenOthers    = 1 << 2,
    SourceAllowNullID           = 1 << 3,
    SourceExtern                = 1 << 4,
    PayloadAutoExpire           = 1 << 5,
    PayloadNoCrossContext       = 1 << 6,
    PayloadNoCrossProcess       = 1 << 7,
    AcceptBeforeDelivery        = 1 << 10,
    AcceptNoDrawDefaultRect     = 1 << 11,
    AcceptNoPreviewTooltip      = 1 << 12,
    AcceptDrawAsHovered         = 1 << 13,
    AcceptPeekOnly              = AcceptBeforeDelivery | AcceptNoDrawDefaultRect,
}

enum ImGuiTreeNodeFlags : int
{
    None                   = 0,
    Selected               = 1 << 0,
    Framed                 = 1 << 1,
    AllowOverlap           = 1 << 2,
    NoTreePushOnOpen       = 1 << 3,
    NoAutoOpenOnLog        = 1 << 4,
    DefaultOpen            = 1 << 5,
    OpenOnDoubleClick      = 1 << 6,
    OpenOnArrow            = 1 << 7,
    Leaf                   = 1 << 8,
    Bullet                 = 1 << 9,
    FramePadding           = 1 << 10,
    SpanAvailWidth         = 1 << 11,
    SpanFullWidth          = 1 << 12,
    SpanTextWidth          = 1 << 13,
    SpanAllColumns         = 1 << 14,
    NavLeftJumpsBackHere   = 1 << 15,
    CollapsingHeader       = Framed | NoTreePushOnOpen | NoAutoOpenOnLog,
}

enum ImGuiComboFlags : int
{
    None           = 0,
    PopupAlignLeft = 1 << 0,
    HeightSmall    = 1 << 1,
    HeightRegular  = 1 << 2,
    HeightLarge    = 1 << 3,
    HeightLargest  = 1 << 4,
    NoArrowButton  = 1 << 5,
    NoPreview      = 1 << 6,
    WidthFitPreview = 1 << 7,
}

enum ImGuiTabBarFlags : int
{
    None                            = 0,
    Reorderable                     = 1 << 0,
    AutoSelectNewTabs               = 1 << 1,
    TabListPopupButton              = 1 << 2,
    NoCloseWithMiddleMouseButton    = 1 << 3,
    NoTabListScrollingButtons       = 1 << 4,
    NoTooltip                       = 1 << 5,
    DrawSelectedOverline            = 1 << 6,
    FittingPolicyMixed              = 1 << 7,
    FittingPolicyShrink             = 1 << 8,
    FittingPolicyScroll             = 1 << 9,
}

enum ImGuiTabItemFlags : int
{
    None                           = 0,
    UnsavedDocument                = 1 << 0,
    SetSelected                    = 1 << 1,
    NoCloseWithMiddleMouseButton   = 1 << 2,
    NoPushId                       = 1 << 3,
    NoTooltip                      = 1 << 4,
    NoReorder                      = 1 << 5,
    Leading                        = 1 << 6,
    Trailing                       = 1 << 7,
    NoAssumedClosure               = 1 << 8,
}

enum ImGuiTableFlags : int
{
    None                 = 0,
    Resizable            = 1 << 0,
    Reorderable          = 1 << 1,
    Hideable             = 1 << 2,
    Sortable             = 1 << 3,
    NoSavedSettings      = 1 << 4,
    ContextMenuInBody    = 1 << 5,
    RowBg                = 1 << 6,
    BordersInnerH        = 1 << 7,
    BordersOuterH        = 1 << 8,
    BordersInnerV        = 1 << 9,
    BordersOuterV        = 1 << 10,
    BordersH             = BordersInnerH | BordersOuterH,
    BordersV             = BordersInnerV | BordersOuterV,
    BordersInner         = BordersInnerV | BordersInnerH,
    BordersOuter         = BordersOuterV | BordersOuterH,
    Borders              = BordersInner | BordersOuter,
    NoBordersInBody      = 1 << 11,
    NoBordersInBodyUntilResize = 1 << 12,
    SizingFixedFit       = 1 << 13,
    SizingFixedSame      = 2 << 13,
    SizingStretchProp    = 3 << 13,
    SizingStretchSame    = 4 << 13,
    NoHostExtendX        = 1 << 16,
    NoHostExtendY        = 1 << 17,
    NoKeepColumnsVisible = 1 << 18,
    PreciseWidths        = 1 << 19,
    NoClip               = 1 << 20,
    PadOuterX            = 1 << 21,
    NoPadOuterX          = 1 << 22,
    NoPadInnerX          = 1 << 23,
    ScrollX              = 1 << 24,
    ScrollY              = 1 << 25,
    SortMulti            = 1 << 26,
    SortTristate         = 1 << 27,
    HighlightHoveredColumn = 1 << 28,
}

enum ImGuiButtonFlags : int
{
    None                   = 0,
    MouseButtonLeft        = 1 << 0,
    MouseButtonRight       = 1 << 1,
    MouseButtonMiddle      = 1 << 2,
    MouseButtonMask_       = 0x7,
    EnableNav              = 1 << 3,
}
