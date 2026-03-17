import { CFG } from './js/config.js';
import { api, formatApiError } from './js/api.js';
import { initRouter } from './js/router.js';
import { getState, setState, subscribe } from './js/store.js';

function setRuntimeStrip() {
  document.getElementById('runtime-mode').textContent = CFG.authModeLabel;
  document.getElementById('runtime-identity').textContent = CFG.identityBase;
  document.getElementById('runtime-project').textContent = CFG.projectBase;
  document.getElementById('runtime-ingest').textContent = CFG.ingestBase;
  document.getElementById('runtime-swagger').innerHTML = Object.entries(CFG.swaggerUrls)
    .map(([key, url]) => `<a href="${url}" target="_blank" rel="noreferrer">${key}</a>`)
    .join(' ');
}

function renderBootError(container, err, routeLabel) {
  const message = err && err.stack ? err.stack : String(err);
  container.innerHTML = `
    <section class="card panel-grid">
      <div class="error-block">
        Failed to render route: ${routeLabel}
\n${message}
      </div>
    </section>
  `;
}

function mountLazyPage(container, routeLabel, loader) {
  let disposed = false;
  let innerCleanup = null;

  container.innerHTML = `
    <section class="card panel-grid">
      <div class="loading-block">Loading ${routeLabel}...</div>
    </section>
  `;

  loader()
    .then((mount) => {
      if (disposed) return;
      innerCleanup = mount(container) || null;
    })
    .catch((err) => {
      if (disposed) return;
      renderBootError(container, err, routeLabel);
      console.error(`UI route failed: ${routeLabel}`, err);
    });

  return () => {
    disposed = true;
    if (typeof innerCleanup === 'function') {
      innerCleanup();
    }
  };
}

function syncNav(path) {
  const links = document.querySelectorAll('[data-route-link]');
  links.forEach((link) => {
    if (link.getAttribute('data-route-link') === path) {
      link.classList.add('active');
    } else {
      link.classList.remove('active');
    }
  });
}

function syncAuthUi() {
  const auth = getState().auth;
  const hasBearerFallback = api.auth.hasBearerFallback();
  const pill = document.getElementById('auth-pill');
  const action = document.getElementById('auth-action');
  const note = document.getElementById('auth-note');
  const session = document.getElementById('runtime-session');

  pill.classList.remove('is-warning', 'is-error');
  action.disabled = auth.status === 'checking';

  if (auth.status === 'authenticated' && auth.user) {
    pill.textContent = `Signed in: ${auth.user.full_name || auth.user.email || auth.user.id}`;
    action.textContent = 'Logout';
    note.textContent = hasBearerFallback
      ? `${auth.user.email || auth.user.id} (Bearer fallback armed for downstream APIs)`
      : auth.user.email || auth.user.id;
    session.textContent = `${auth.user.full_name || 'User'} <${auth.user.email || auth.user.id}>`;
    return;
  }

  if (auth.status === 'error') {
    pill.textContent = 'Session check failed';
    pill.classList.add('is-error');
    action.textContent = 'Retry';
    note.textContent = auth.error || 'Cannot verify production session.';
    session.textContent = auth.error || 'Unknown error';
    return;
  }

  if (auth.status === 'checking') {
    pill.textContent = 'Checking session';
    pill.classList.add('is-warning');
    action.textContent = 'Checking...';
    note.textContent = hasBearerFallback
      ? 'Verifying cookie session and preparing Bearer fallback for downstream APIs'
      : 'Verifying OAuth cookie session on smap-api.tantai.dev';
    session.textContent = 'Checking production session';
    return;
  }

  pill.textContent = hasBearerFallback ? 'Cookie missing, Bearer fallback armed' : 'Not signed in';
  pill.classList.add('is-warning');
  action.textContent = 'Login with Google';
  note.textContent = hasBearerFallback
    ? 'Identity cookie is not available, but downstream API calls will include the stored Bearer token.'
    : 'Use production Google OAuth, then return here to call protected APIs.';
  session.textContent = hasBearerFallback ? 'Bearer fallback active' : 'Anonymous';
}

async function refreshAuth({ silent = false } = {}) {
  if (!silent) {
    setState({
      auth: {
        status: 'checking',
        user: null,
        error: '',
      },
    });
  }

  try {
    const result = await api.auth.me();

    if (result.status === 401) {
      setState({
        auth: {
          status: 'anonymous',
          user: null,
          error: '',
        },
      });
      return;
    }

    setState({
      auth: {
        status: 'authenticated',
        user: result.data || null,
        error: '',
      },
    });
  } catch (err) {
    setState({
      auth: {
        status: 'error',
        user: null,
        error: formatApiError(err),
      },
    });
  }
}

async function onAuthAction() {
  const auth = getState().auth;

  if (auth.status === 'checking') {
    return;
  }

  if (auth.status === 'error') {
    await refreshAuth();
    return;
  }

  if (auth.status === 'authenticated') {
    try {
      await api.auth.logout();
    } finally {
      api.auth.clearBearerFallback();
      await refreshAuth();
    }
    window.location.reload();
    return;
  }

  window.location.assign(api.auth.buildLoginUrl(window.location.href));
}

function main() {
  api.auth.hydrateBearerFallbackFromLocation();
  setRuntimeStrip();
  syncAuthUi();
  subscribe(syncAuthUi);

  const authAction = document.getElementById('auth-action');
  authAction.addEventListener('click', onAuthAction);

  const app = document.getElementById('app');

  initRouter({
    app,
    defaultPath: '/campaigns',
    routes: {
      '/campaigns': (container) => {
        syncNav('/campaigns');
        return mountLazyPage(container, 'campaigns', async () => {
          const mod = await import('./js/pages/campaigns.js');
          return mod.mountCampaignsPage;
        });
      },
      '/projects': (container) => {
        syncNav('/projects');
        return mountLazyPage(container, 'projects', async () => {
          const mod = await import('./js/pages/projects.js');
          return mod.mountProjectsPage;
        });
      },
    },
  });

  refreshAuth();
}

document.addEventListener('DOMContentLoaded', main);
