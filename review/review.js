"use strict";
(async function () {
  const gallery = document.getElementById("capture-gallery");
  try {
    const response = await fetch("../marketing/screenshots/provenance.json", {cache: "no-store"});
    if (!response.ok) throw new Error("Capture manifest unavailable");
    const manifest = await response.json();
    const captures = Array.isArray(manifest.captures) ? manifest.captures : [];
    if (captures.length === 0) {
      gallery.firstElementChild.innerHTML = "<b>Runtime captures pending</b>No captured gameplay has been recorded in the manifest yet. Branding artwork is shown separately below.";
    } else {
      gallery.textContent = "";
      const profiles = {phone: "Phone", tablet7: "7-inch viewport", tablet10: "10-inch viewport"};
      const filter = document.createElement("div"); filter.className = "actions"; filter.setAttribute("aria-label", "Capture profile");
      const figures = [];
      const profileNames = [...new Set(captures.map(c => c.profile))];
      const buttons = [];
      for (const profile of profileNames) {
        const button = document.createElement("button"); button.type = "button"; button.className = "button secondary";
        button.textContent = profiles[profile] || profile; button.setAttribute("aria-pressed", "false");
        button.addEventListener("click", () => {
          figures.forEach(entry => { entry.figure.hidden = entry.profile !== profile; });
          buttons.forEach(entry => { const active = entry.profile === profile; entry.button.setAttribute("aria-pressed", String(active)); entry.button.className = active ? "button" : "button secondary"; });
        });
        buttons.push({button, profile}); filter.append(button);
      }
      gallery.before(filter);
      for (const capture of captures) {
        if (typeof capture.path !== "string" || !/^[a-zA-Z0-9_./-]+\.png$/.test(capture.path) || capture.path.includes("..")) continue;
        const figure = document.createElement("figure"); figure.className = "capture";
        const link = document.createElement("a"); link.href = "../marketing/screenshots/" + capture.path;
        const picture = document.createElement("img"); picture.src = link.href; picture.loading = "lazy";
        picture.alt = capture.description || "Prism Quarry rendered runtime capture";
        picture.addEventListener("error", () => { figure.textContent = ""; figure.className = "pending"; figure.textContent = "Capture file unavailable: " + capture.path; });
        link.append(picture);
        const caption = document.createElement("figcaption");
        const name = document.createElement("strong"); name.textContent = `${profiles[capture.profile] || capture.profile || "Runtime viewport"} · ${capture.view || "capture"}`;
        const details = document.createElement("span"); details.textContent = `${capture.width} × ${capture.height} · ${capture.device_class || "device class unrecorded"}. ${capture.description || ""}`;
        const method = document.createElement("div"); method.textContent = capture.method || "Capture method unrecorded";
        caption.append(name, details, method); figure.append(link, caption); gallery.append(figure); figures.push({figure, profile: capture.profile});
      }
      if (!gallery.childElementCount) throw new Error("No valid capture paths in manifest");
      if (buttons.length) buttons[0].button.click();
    }
    if (manifest.summary) document.getElementById("capture-note").textContent = manifest.summary;
    else if (manifest.evidence_type) document.getElementById("capture-note").textContent = manifest.evidence_type + ". These are desktop layout profiles, not physical-device or Android emulator evidence. Each image links to its unmodified full-size PNG.";
  } catch (error) {
    console.info("Runtime evidence not loaded:", error.message);
  }
  try {
    const response = await fetch("../build.json", {cache: "no-store"});
    if (!response.ok) return;
    const build = await response.json();
    document.getElementById("build-identity").textContent = `Source: ${build.source_identity}. Engine: ${build.engine}. Single-threaded Web. ${build.uncommitted_changes ? "LOCAL UNCOMMITTED BUILD — not an exact committed revision." : "Clean source recorded at assembly."} Deployment must be verified separately.`;
  } catch (_) { /* A raw source checkout has no build identity. */ }
})();

(async function renderNativeEvidence() {
  const gallery = document.getElementById("native-gallery");
  if (!gallery) return;
  try {
    const response = await fetch("../marketing/screenshots/android-provenance.json", {cache: "no-store"});
    if (!response.ok) return;
    const manifest = await response.json();
    if (!Array.isArray(manifest.captures) || !manifest.captures.length) return;
    gallery.textContent = "";
    for (const capture of manifest.captures) {
      if (typeof capture.path !== "string" || !/^[a-zA-Z0-9_./-]+\.png$/.test(capture.path) || capture.path.includes("..")) continue;
      const figure = document.createElement("figure"); figure.className = "capture";
      const link = document.createElement("a"); link.href = "../marketing/screenshots/" + capture.path;
      const picture = document.createElement("img"); picture.src = link.href; picture.loading = "lazy"; picture.alt = capture.description;
      picture.addEventListener("error", () => { figure.textContent = ""; figure.className = "pending"; figure.textContent = "Native capture file unavailable: " + capture.path; });
      link.append(picture);
      const caption = document.createElement("figcaption");
      const title = document.createElement("strong"); title.textContent = capture.title;
      const details = document.createElement("span"); details.textContent = `${capture.width} × ${capture.height} · actual Android emulator. ${capture.description}`;
      const method = document.createElement("div"); method.textContent = capture.method;
      caption.append(title, details, method); figure.append(link, caption);
      const destination = capture.category === "ad_qa" ? document.getElementById("native-ad-gallery") : capture.featured ? gallery : document.getElementById("native-extra-gallery");
      destination.append(figure);
    }
    document.getElementById("native-extra").hidden = !document.getElementById("native-extra-gallery").childElementCount;
    document.getElementById("native-ad").hidden = !document.getElementById("native-ad-gallery").childElementCount;
    document.getElementById("native-note").textContent = manifest.summary;
  } catch (error) { console.info("Native evidence not loaded:", error.message); }
})();
