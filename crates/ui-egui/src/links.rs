//! Project links (Help menu, About dialog). FisiRevela is the Suíte FisiLab (UFRGS) version of
//! LightCraft: the links go to the suite, its manifesto, the original project and this fork's
//! issue tracker. Nothing here is contacted unless the user clicks it.

/// The original project's id in its repository URL.
pub const UPSTREAM_APP: &str = "lightcraft";
/// The original project's source repository (LightCraft, by the ArtCraft Team and contributors).
pub const UPSTREAM: &str = "https://github.com/storytold/lightcraft";
/// The Suíte FisiLab page (source code, installers, credits).
pub const SUITE: &str = fisilab_brand::SUITE_URL;
/// The manifesto for free technologies.
pub const MANIFESTO: &str = fisilab_brand::MANIFESTO_URL;
/// This app's id in the suite's repositories.
pub const APP: &str = "fisirevela";
/// This fork's source repository.
pub const GITHUB: &str = "https://github.com/mrcandrade/fisirevela";

/// The user documentation (docs/ in the original repository).
pub const HELP: &str = "https://github.com/storytold/lightcraft/tree/main/docs";

/// (UI command id, menu label, URL) for each link, in Help-menu order.
pub const LINKS: &[(&str, &str, &str)] = &[
    ("app.help", "FisiRevela Help", HELP),
    ("app.suite", "Site da Suíte FisiLab", SUITE),
    ("app.manifesto", "Manifesto pelas tecnologias livres", MANIFESTO),
    ("app.upstream", "Projeto original (LightCraft)", UPSTREAM),
    ("app.feedback", "Reportar um problema", FEEDBACK),
];

/// Where problem reports go (this fork's issues).
pub const FEEDBACK: &str = "https://github.com/mrcandrade/fisirevela/issues";

/// The URL behind a link command id.
pub fn url_of(cmd: &str) -> Option<&'static str> {
    LINKS.iter().find(|(id, _, _)| *id == cmd).map(|(_, _, u)| *u)
}

/// Open `url` in the user's browser (through the host's `open_url` service).
pub fn open(app: &mut crate::LightcraftApp, url: &str) -> Result<serde_json::Value, String> {
    let open = app.services.open_url.as_mut().ok_or("can't open links here")?;
    open(url)?;
    Ok(serde_json::json!({ "url": url }))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn links_are_https_and_name_this_app() {
        for (id, label, url) in LINKS {
            assert!(url.starts_with("https://"), "{id}");
            assert!(!label.is_empty());
            assert_eq!(url_of(id), Some(*url));
        }
        assert!(GITHUB.ends_with(&format!("/mrcandrade/{APP}")));
        assert!(FEEDBACK.starts_with(GITHUB));
        assert!(UPSTREAM.ends_with(&format!("/storytold/{UPSTREAM_APP}")));
    }

    /// Nothing links to the ArtCraft community or website any more (their name and logos are
    /// trademarks outside the licence).
    #[test]
    fn no_link_goes_to_artcraft() {
        for (id, label, url) in LINKS {
            assert!(!url.contains("artcraft") && !url.contains("discord"), "{id}: {url}");
            assert!(!label.contains("ArtCraft") && !label.contains("Discord"), "{id}: {label}");
        }
    }
}
