//! Windows only: embed the app icon and version info (VERSIONINFO) into `fisirevela.exe`, so
//! Explorer, the taskbar, the Start menu and Alt-Tab show the FisiRevela icon (Suíte FisiLab).
//!
//! On every other target this does nothing. A missing resource compiler is a warning, so a
//! cross-compile from macOS or Linux still links, unless `LIGHTCRAFT_REQUIRE_WINRES=1` turns it
//! into an error (for release builds).

fn main() {
    println!("cargo:rerun-if-changed=build.rs");
    println!("cargo:rerun-if-changed=../../assets/fisilab/fisirevela.ico");
    println!("cargo:rerun-if-env-changed=LIGHTCRAFT_REQUIRE_WINRES");
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() != Ok("windows") {
        return;
    }
    let mut res = winresource::WindowsResource::new();
    res.set_icon("../../assets/fisilab/fisirevela.ico")
        .set("ProductName", "FisiRevela")
        .set("FileDescription", "FisiRevela — Revelação e catálogo de fotos (Suíte FisiLab)")
        .set("CompanyName", "FisiLab — LARFIC/UFRGS")
        .set(
            "LegalCopyright",
            "Baseado no LightCraft (© ArtCraft Team e contribuidores). Modificações © 2026 FisiLab — LARFIC/UFRGS. MIT OR Apache-2.0.",
        )
        .set("OriginalFilename", "fisirevela.exe")
        .set("InternalName", "fisirevela");
    if let Err(e) = res.compile() {
        if std::env::var_os("LIGHTCRAFT_REQUIRE_WINRES").is_some() {
            panic!("embedding Windows resources failed: {e}");
        }
        println!("cargo:warning=fisirevela.exe built without icon/version resources: {e}");
    }
}
