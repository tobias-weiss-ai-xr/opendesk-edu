(function() {
  'use strict';
  
  const currentHost = window.location.hostname;
  const currentOrigin = window.location.origin;
  
  console.log('Domain-aware script loaded for:', currentHost);
  
  const isSmeDomain = currentHost.includes('opendesk-sme.org');
  const isEduDomain = currentHost.includes('opendesk-edu.org');
  
  const urlMappings = {
    'demo.opendesk-edu.org': currentHost,
    'portal.demo.opendesk-edu.org': `${window.location.hostname}`,
    'id.demo.opendesk-edu.org': `id.${currentHost.replace('demo.', '')}`,
    'ics.demo.opendesk-edu.org': `ics.${currentHost.replace('demo.', '')}`,
    'wiki.demo.opendesk-edu.org': `wiki.${currentHost.replace('demo.', '')}`,
    'files.demo.opendesk-edu.org': `files.${currentHost.replace('demo.', '')}`,
    'meet.demo.opendesk-edu.org': `meet.${currentHost.replace('demo.', '')}`,
  };
  
  function rewriteUrl(url) {
    if (!url) return url;
    
    let newUrl = url;
    for (const [oldUrl, newDomain] of Object.entries(urlMappings)) {
      if (url.includes(oldUrl)) {
        newUrl = url.replace(oldUrl, newDomain);
        console.log('Rewriting URL:', url, '->', newUrl);
      }
    }
    return newUrl;
  }
  
  // Intercept window.location.href assignments
  const originalLocation = window.location;
  const locationDescriptor = Object.getOwnPropertyDescriptor(window.Location.prototype, 'href');
  
  Object.defineProperty(originalLocation, 'href', {
    set: function(value) {
      const rewritten = rewriteUrl(value);
      if (rewritten !== value) {
        console.log('Intercepting location.href:', value, '->', rewritten);
        locationDescriptor.set.call(this, rewritten);
      } else {
        locationDescriptor.set.call(this, value);
      }
    },
    get: function() {
      return locationDescriptor.get.call(this);
    }
  });
  
  // Override window.location.href setter
  const locationSetter = Object.getOwnPropertyDescriptor(window, 'location').set;
  Object.defineProperty(window, 'location', {
    set: function(url) {
      const rewritten = rewriteUrl(url);
      if (rewritten !== url) {
        console.log('Intercepting window.location:', url, '->', rewritten);
        locationSetter.call(window, rewritten);
      } else {
        locationSetter.call(window, url);
      }
    },
    get: function() {
      return originalLocation;
    }
  });
  
  // Override window.open
  const originalOpen = window.open;
  window.open = function(url, target, features) {
    const rewritten = rewriteUrl(url);
    if (rewritten !== url) {
      console.log('Intercepting window.open:', url, '->', rewritten);
      return originalOpen.call(this, rewritten, target, features);
    }
    return originalOpen.call(this, url, target, features);
  };
  
  function overrideUrls(element) {
    if (!element) return;
  
    const links = element.querySelectorAll('a[href]');
    links.forEach(link => {
      const originalHref = link.getAttribute('href');
      let newHref = originalHref;
  
      for (const [oldUrl, newUrl] of Object.entries(urlMappings)) {
        if (originalHref && originalHref.includes(oldUrl)) {
          newHref = originalHref.replace(oldUrl, newUrl);
          console.log('Overriding URL:', originalHref, '->', newHref);
          link.setAttribute('href', newHref);
        }
      }
    });
  
    const urlAttributes = ['data-url', 'data-login', 'data-redirect', 'action', 'data-auth', 'data-oidc'];
    urlAttributes.forEach(attr => {
      const elements = element.querySelectorAll(`[${attr}]`);
      elements.forEach(el => {
        const originalValue = el.getAttribute(attr);
        if (originalValue) {
          let newValue = originalValue;
          for (const [oldUrl, newUrl] of Object.entries(urlMappings)) {
            if (originalValue.includes(oldUrl)) {
              newValue = originalValue.replace(oldUrl, newUrl);
              console.log(`Overriding ${attr}:`, originalValue, '->', newValue);
              el.setAttribute(attr, newValue);
            }
          }
        }
      });
    });
  }
  
  function init() {
    console.log('Initializing domain-aware URL overrides');
  
    overrideUrls(document.body);
  
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.addedNodes) {
          mutation.addedNodes.forEach((node) => {
            if (node.nodeType === Node.ELEMENT_NODE) {
              overrideUrls(node);
            }
          });
        }
      });
    });
  
    observer.observe(document.body, {
      childList: true,
      subtree: true
    });
  
    console.log('Domain-aware URL overrides initialized for', currentHost);
  }
  
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
  
  window.DomainAware = {
    getCurrentDomain: () => currentHost,
    getCurrentOrigin: () => currentOrigin,
    isSmeDomain: () => isSmeDomain,
    isEduDomain: () => isEduDomain,
    rewriteUrl: rewriteUrl
  };
  
})();