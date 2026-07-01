/// d_imgui.imconfig — project-local configuration for the cimgui D shim.
/// Copy this file into your project's source tree to override the defaults.
/// vibe3d's copy lives at source/d_imgui/imconfig.d and shadows this one.
module d_imgui.imconfig;

// ImTextureID: OpenGL texture handle.  vibe3d passes GLuint (uint) values which
// always fit in a signed int.  Keep as int for source compatibility with
// existing vibe3d call sites (cast(ImTextureID) glTex).
//
// IMPORTANT: ImTextureID values must ONLY cross the D→C++ boundary via
// igVibe3d_Image(), which zero-extends the int to ImU64 on the C++ side.
// Never pass an ImTextureID (or read TexRef/atlas texid) by value directly
// through any other cimgui call — the C++ side stores it as ImU64 and reading
// it as int would produce UB on big-endian or future 64-bit-native TexID builds.
alias ImTextureID = int;
