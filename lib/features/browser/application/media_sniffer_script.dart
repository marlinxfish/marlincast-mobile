class MediaSnifferScript {
  static const source = r'''
(function() {
  if (window.__marlinMediaSnifferInstalled) return;
  window.__marlinMediaSnifferInstalled = true;

  const qualityFromHeight = (height) => {
    if (!height || height <= 0) return null;
    if (height >= 2160) return '2160p';
    if (height >= 1440) return '1440p';
    if (height >= 1080) return '1080p';
    if (height >= 720) return '720p';
    if (height >= 480) return '480p';
    if (height >= 360) return '360p';
    return height + 'p';
  };

  const qualityFromUrl = (url) => {
    if (!url || typeof url !== 'string') return null;
    const lower = url.toLowerCase();
    if (lower.includes('.m3u8') || lower.includes('.mpd')) return 'Adaptive';
    const match = lower.match(/(?:^|[^0-9])([0-9]{3,4})p(?:[^0-9]|$)/);
    return match ? match[1] + 'p' : null;
  };

  const thumbnailFromDocument = () => {
    const selectors = [
      'meta[property="og:image"]',
      'meta[name="twitter:image"]',
      'link[rel="image_src"]'
    ];
    for (const selector of selectors) {
      const element = document.querySelector(selector);
      const value = element && (element.content || element.href);
      if (value) return new URL(value, window.location.href).href;
    }
    return null;
  };

  const report = (url, source, metadata) => {
    if (!url || typeof url !== 'string') return;
    const width = metadata && metadata.width ? Math.round(metadata.width) : null;
    const height = metadata && metadata.height ? Math.round(metadata.height) : null;
    const absoluteUrl = new URL(url, window.location.href).href;
    window.flutter_inappwebview.callHandler('marlinMediaDetected', {
      url: absoluteUrl,
      source: source,
      pageUrl: window.location.href,
      width: width,
      height: height,
      qualityLabel: qualityFromHeight(height) || qualityFromUrl(absoluteUrl),
      thumbnailUrl: metadata && metadata.thumbnailUrl ? metadata.thumbnailUrl : thumbnailFromDocument()
    });
  };

  const looksLikeMedia = (url) => {
    if (!url || typeof url !== 'string') return false;
    const lower = url.toLowerCase();
    return lower.includes('.mp4') ||
      lower.includes('.m3u8') ||
      lower.includes('.mpd') ||
      lower.includes('.m4v') ||
      lower.includes('.mov') ||
      lower.includes('.webm') ||
      lower.includes('.mkv') ||
      lower.includes('video%2f') ||
      lower.includes('mime=video') ||
      lower.includes('type=video');
  };

  const scanMediaElements = () => {
    document.querySelectorAll('video, audio, source').forEach((element) => {
      const mediaElement = element.tagName === 'SOURCE' ? element.parentElement : element;
      const metadata = {
        width: mediaElement && mediaElement.videoWidth,
        height: mediaElement && mediaElement.videoHeight,
        thumbnailUrl: mediaElement && mediaElement.poster ? new URL(mediaElement.poster, window.location.href).href : null,
      };
      if (element.currentSrc) report(element.currentSrc, 'htmlMediaElement', metadata);
      if (element.src) report(element.src, 'htmlMediaElement', metadata);
    });
  };

  const originalFetch = window.fetch;
  if (originalFetch) {
    window.fetch = function(input, init) {
      const url = typeof input === 'string' ? input : input && input.url;
      if (looksLikeMedia(url)) report(url, 'javascriptFetch', null);
      return originalFetch.apply(this, arguments).then((response) => {
        const contentType = response.headers && response.headers.get('content-type');
        if (contentType && contentType.toLowerCase().startsWith('video/')) {
          report(response.url || url, 'javascriptFetch', null);
        }
        return response;
      });
    };
  }

  const originalOpen = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function(method, url) {
    if (looksLikeMedia(url)) report(url, 'javascriptFetch', null);
    return originalOpen.apply(this, arguments);
  };

  scanMediaElements();
  window.addEventListener('loadedmetadata', scanMediaElements, true);
  window.addEventListener('play', scanMediaElements, true);
  new MutationObserver(scanMediaElements).observe(document.documentElement, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ['src']
  });
})();
''';
}
