/// d_imgui.imconfig — project-local configuration for the cimgui D shim.
/// Copy this file into your project's source tree to override the defaults.
/// vibe3d's copy lives at source/d_imgui/imconfig.d and shadows this one.
module d_imgui.imconfig;

// ImTextureID: OpenGL texture handle.  vibe3d passes GLuint (uint) values which
// always fit in a signed int.  Keep as int for source compatibility with
// existing vibe3d call sites (cast(ImTextureID) glTex).
alias ImTextureID = int;
