class CosmeticFilterScript {
  static const forceLightMode = r'''
(function() {
  var meta = document.querySelector('meta[name="color-scheme"]');
  if (!meta) {
    meta = document.createElement('meta');
    meta.name = 'color-scheme';
    document.head.appendChild(meta);
  }
  meta.content = 'only light';
})();
''';

  static const source = r'''
(function() {
  const selectors = [
    '[id*="ad"]',
    '[class*="ad-"]',
    '[class*="ads"]',
    '[class*="popup"]',
    '[class*="overlay"]',
    'iframe[src*="ads"]',
    'iframe[src*="doubleclick"]'
  ];

  function removeMatches() {
    for (const selector of selectors) {
      document.querySelectorAll(selector).forEach((element) => {
        const style = window.getComputedStyle(element);
        const isLargeOverlay = style.position === 'fixed' &&
          element.offsetWidth > window.innerWidth * 0.5 &&
          element.offsetHeight > window.innerHeight * 0.25;

        if (isLargeOverlay || selector.includes('iframe') || selector.includes('popup')) {
          element.remove();
        }
      });
    }
  }

  removeMatches();
  new MutationObserver(removeMatches).observe(document.documentElement, {
    childList: true,
    subtree: true
  });
})();
''';
}
