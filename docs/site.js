// Theme and language switching, shared by index.html and privacy.html
(function() {
  const htmlEl = document.documentElement;
  const themeToggleBtn = document.getElementById('themeToggleBtn');
  const langToggleBtn = document.getElementById('langToggleBtn');

  // Each page names itself in both languages on its <html> element.
  const titles = {
    ar: htmlEl.dataset.titleAr,
    en: htmlEl.dataset.titleEn
  };

  const descriptions = {
    ar: htmlEl.dataset.descAr,
    en: htmlEl.dataset.descEn
  };

  /* Theme Handling */
  function getEffectiveTheme() {
    return htmlEl.getAttribute('data-theme') || 'light';
  }

  function setTheme(theme) {
    htmlEl.setAttribute('data-theme', theme);
    try {
      localStorage.setItem('tadbeer-theme', theme);
    } catch (e) {}
  }

  if (themeToggleBtn) {
    themeToggleBtn.addEventListener('click', function() {
      const current = getEffectiveTheme();
      const next = current === 'dark' ? 'light' : 'dark';
      setTheme(next);
    });
  }

  /* Language Handling */
  function getEffectiveLang() {
    return htmlEl.getAttribute('lang') || 'ar';
  }

  function setLanguage(lang) {
    htmlEl.setAttribute('lang', lang);
    htmlEl.setAttribute('dir', lang === 'ar' ? 'rtl' : 'ltr');

    if (titles[lang]) {
      document.title = titles[lang];
    }
    const metaDesc = document.querySelector('meta[name="description"]');
    if (metaDesc && descriptions[lang]) {
      metaDesc.setAttribute('content', descriptions[lang]);
    }

    try {
      localStorage.setItem('tadbeer-lang', lang);
    } catch (e) {}
  }

  if (langToggleBtn) {
    langToggleBtn.addEventListener('click', function() {
      const current = getEffectiveLang();
      const next = current === 'ar' ? 'en' : 'ar';
      setLanguage(next);
    });
  }

  // A language restored before first paint also needs its title and description.
  setLanguage(getEffectiveLang());

  /* Multi-tab Synchronization */
  window.addEventListener('storage', function(e) {
    if (e.key === 'tadbeer-theme' && (e.newValue === 'light' || e.newValue === 'dark')) {
      htmlEl.setAttribute('data-theme', e.newValue);
    }
    if (e.key === 'tadbeer-lang' && (e.newValue === 'ar' || e.newValue === 'en')) {
      setLanguage(e.newValue);
    }
  });
})();
