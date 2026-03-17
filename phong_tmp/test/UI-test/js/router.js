function normalizePath(hash) {
  if (!hash || hash === '#') {
    return '/';
  }
  if (!hash.startsWith('#/')) {
    return '/';
  }
  return hash.slice(1);
}

export function initRouter({ app, routes, defaultPath }) {
  let cleanup = null;

  function render() {
    const path = normalizePath(window.location.hash);
    const mount = routes[path] || routes[defaultPath];

    if (cleanup) {
      cleanup();
      cleanup = null;
    }

    if (!routes[path]) {
      window.location.hash = `#${defaultPath}`;
      return;
    }

    cleanup = mount(app) || null;
  }

  if (!window.location.hash || normalizePath(window.location.hash) === '/') {
    window.location.hash = `#${defaultPath}`;
  }

  window.addEventListener('hashchange', render);
  render();

  return () => {
    window.removeEventListener('hashchange', render);
    if (cleanup) {
      cleanup();
    }
  };
}
