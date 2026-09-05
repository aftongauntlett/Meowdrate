// Footer light/dark toggle. Defaults to the OS/browser preference
// (no localStorage entry, no data-theme attribute) until a visitor
// picks one explicitly; see the blocking snippet in <head> that applies
// a stored choice before first paint to avoid a flash of the wrong theme.
(function () {
  "use strict";

  var STORAGE_KEY = "meowdrate-theme";
  var THEME_COLORS = { light: "#f5f7fc", dark: "#05070c" };
  var root = document.documentElement;
  var darkMedia = window.matchMedia("(prefers-color-scheme: dark)");

  function effectiveTheme() {
    var forced = root.getAttribute("data-theme");
    if (forced === "light" || forced === "dark") return forced;
    return darkMedia.matches ? "dark" : "light";
  }

  // Browsers only re-read <meta name=theme-color media=...> against OS
  // preference, not our data-theme override, so once a visitor picks a
  // theme by hand we mirror it into a plain (medialess) meta tag too.
  function syncThemeColorMeta() {
    var forced = root.getAttribute("data-theme");
    var dynamic = document.getElementById("theme-color-dynamic");
    if (forced === "light" || forced === "dark") {
      if (!dynamic) {
        dynamic = document.createElement("meta");
        dynamic.id = "theme-color-dynamic";
        dynamic.setAttribute("name", "theme-color");
        document.head.appendChild(dynamic);
      }
      dynamic.setAttribute("content", THEME_COLORS[forced]);
    } else if (dynamic) {
      dynamic.remove();
    }
  }

  function updateLabels() {
    var theme = effectiveTheme();
    var next = theme === "dark" ? "light" : "dark";
    document.querySelectorAll("[data-theme-toggle]").forEach(function (btn) {
      btn.setAttribute("aria-label", "Switch to " + next + " theme");
      btn.setAttribute("title", "Switch to " + next + " theme");
    });
  }

  document.querySelectorAll("[data-theme-toggle]").forEach(function (btn) {
    btn.addEventListener("click", function () {
      var newTheme = effectiveTheme() === "dark" ? "light" : "dark";
      root.setAttribute("data-theme", newTheme);
      try {
        localStorage.setItem(STORAGE_KEY, newTheme);
      } catch (e) {}
      syncThemeColorMeta();
      updateLabels();
    });
  });

  darkMedia.addEventListener("change", updateLabels);
  syncThemeColorMeta();
  updateLabels();
})();
