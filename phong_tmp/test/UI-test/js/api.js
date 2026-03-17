import { CFG } from './config.js';
import { effectiveStatus, pretty } from './components.js';

const FALLBACK_BEARER_TOKEN_KEY = 'smap_prod_bearer_token';

class ApiError extends Error {
  constructor(message, details) {
    super(message);
    this.name = 'ApiError';
    this.details = details;
  }
}

function createTraceId() {
  if (globalThis.crypto && typeof globalThis.crypto.randomUUID === 'function') {
    return globalThis.crypto.randomUUID();
  }

  return `ui-${Date.now()}-${Math.random().toString(16).slice(2, 10)}`;
}

function withTimeout(ms) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), ms);
  return {
    signal: controller.signal,
    done: () => clearTimeout(timer),
  };
}

function readStoredBearerToken() {
  try {
    const value = window.localStorage.getItem(FALLBACK_BEARER_TOKEN_KEY) || '';
    return value.trim();
  } catch (_err) {
    return '';
  }
}

function writeStoredBearerToken(token) {
  try {
    if (!token) {
      window.localStorage.removeItem(FALLBACK_BEARER_TOKEN_KEY);
      return;
    }
    window.localStorage.setItem(FALLBACK_BEARER_TOKEN_KEY, token);
  } catch (_err) {
    // Ignore storage failures in static test UI.
  }
}

function canMirrorLocalCookie(baseUrl) {
  try {
    const fallbackUrl = new URL(baseUrl);
    const pageUrl = new URL(window.location.href);
    return fallbackUrl.hostname === pageUrl.hostname && (
      fallbackUrl.hostname === 'localhost' || fallbackUrl.hostname === '127.0.0.1'
    );
  } catch (_err) {
    return false;
  }
}

function writeLocalFallbackCookie(token) {
  if (!canMirrorLocalCookie(CFG.projectFallbackBase)) {
    return;
  }

  const cookieName = CFG.authCookieName || 'smap_auth_token';
  const encodedName = encodeURIComponent(cookieName);

  if (!token) {
    document.cookie = `${encodedName}=; Path=/; Max-Age=0; SameSite=Lax`;
    return;
  }

  const encodedValue = encodeURIComponent(token);
  document.cookie = `${encodedName}=${encodedValue}; Path=/; Max-Age=28800; SameSite=Lax`;
}

function syncLocalFallbackCookie(token) {
  try {
    writeLocalFallbackCookie(token);
  } catch (_err) {
    // Ignore cookie write failures in the static test UI.
  }
}

function isProtectedApiBase(baseUrl) {
  return (
    baseUrl === CFG.projectBase ||
    baseUrl === CFG.projectFallbackBase ||
    baseUrl === CFG.ingestBase ||
    baseUrl === CFG.knowledgeBase
  );
}

function getFallbackBearerToken() {
  const stored = readStoredBearerToken();
  if (stored) {
    return stored;
  }
  return (CFG.fallbackBearerToken || '').trim();
}

async function request(baseUrl, path, options = {}) {
  const method = options.method || 'GET';
  const url = `${baseUrl}${path}`;
  const authMode = options.authMode || 'auto';
  const headers = {
    Accept: 'application/json',
    'Accept-Language': 'vi-VN,vi;q=0.9',
    'X-Trace-Id': createTraceId(),
    ...(options.headers || {}),
  };

  const bearerToken = getFallbackBearerToken();
  const allowBearer =
    authMode !== 'cookie-only' &&
    authMode !== 'cookie' &&
    authMode !== 'credentials-only';

  if (!headers.Authorization && allowBearer && bearerToken && isProtectedApiBase(baseUrl)) {
    headers.Authorization = `Bearer ${bearerToken}`;
  }

  let body;
  if (options.body !== undefined) {
    headers['Content-Type'] = 'application/json';
    body = JSON.stringify(options.body);
  }

  const timeout = withTimeout(CFG.requestTimeoutMs);
  let response;
  let parsed;

  try {
    response = await fetch(url, {
      method,
      headers,
      body,
      signal: timeout.signal,
      credentials: 'include',
    });

    const raw = await response.text();
    try {
      parsed = raw ? JSON.parse(raw) : null;
    } catch (_err) {
      parsed = raw;
    }
  } catch (err) {
    if (err.name === 'AbortError') {
      throw new ApiError(`Request timeout: ${method} ${path}`, {
        url,
        method,
        reason: 'timeout',
      });
    }
    throw new ApiError(`Network error: ${method} ${path}`, {
      url,
      method,
      reason: err.message,
    });
  } finally {
    timeout.done();
  }

  const status = effectiveStatus(response.status, parsed);
  const allow = options.allowStatuses || [200];

  if (!allow.includes(status)) {
    const msg = extractErrorMessage(parsed, method, path, status);
    throw new ApiError(msg, {
      url,
      method,
      httpStatus: response.status,
      status,
      body: parsed,
      requestBody: options.body,
    });
  }

  return {
    httpStatus: response.status,
    status,
    body: parsed,
    data: extractData(parsed),
  };
}

async function requestWithBaseFallback(primaryBaseUrl, fallbackBaseUrl, path, options = {}) {
  const primaryOptions = {
    ...options,
    authMode: options.authMode || 'cookie-only',
  };
  const fallbackOptions = {
    ...options,
    authMode: options.fallbackAuthMode || 'auto',
  };

  try {
    return await request(primaryBaseUrl, path, primaryOptions);
  } catch (err) {
    const shouldFallback =
      err instanceof ApiError &&
      fallbackBaseUrl &&
      err.details &&
      err.details.status === 401;

    if (!shouldFallback) {
      throw err;
    }

    return request(fallbackBaseUrl, path, fallbackOptions);
  }
}

function extractData(parsed) {
  if (!parsed || typeof parsed !== 'object') {
    return null;
  }
  if (parsed.data !== undefined) {
    return parsed.data;
  }
  return parsed;
}

function extractErrorMessage(parsed, method, path, status) {
  if (parsed && typeof parsed === 'object') {
    if (parsed.error && typeof parsed.error === 'object' && parsed.error.message) {
      return parsed.error.message;
    }
    if (parsed.message) {
      return parsed.message;
    }
  }
  return `Request failed: ${method} ${path} (${status})`;
}

function qs(params) {
  const query = new URLSearchParams();
  Object.entries(params || {}).forEach(([key, val]) => {
    if (val === undefined || val === null || val === '') return;
    query.set(key, String(val));
  });
  const s = query.toString();
  return s ? `?${s}` : '';
}

export const api = {
  rawRequest: request,

  auth: {
    hydrateBearerFallbackFromLocation() {
      const url = new URL(window.location.href);
      const token =
        url.searchParams.get('token') ||
        url.searchParams.get('access_token') ||
        url.searchParams.get('bearer');

      if (!token) {
        const fallbackToken = getFallbackBearerToken();
        syncLocalFallbackCookie(fallbackToken);
        return fallbackToken;
      }

      writeStoredBearerToken(token.trim());
      syncLocalFallbackCookie(token.trim());
      url.searchParams.delete('token');
      url.searchParams.delete('access_token');
      url.searchParams.delete('bearer');
      window.history.replaceState({}, '', `${url.pathname}${url.search}${url.hash}`);
      return getFallbackBearerToken();
    },
    getBearerFallbackToken: () => getFallbackBearerToken(),
    hasBearerFallback: () => Boolean(getFallbackBearerToken()),
    clearBearerFallback() {
      writeStoredBearerToken('');
      syncLocalFallbackCookie('');
    },
    buildLoginUrl(redirectUrl = window.location.href) {
      const q = new URLSearchParams({ redirect: redirectUrl });
      return `${CFG.identityBase}/authentication/login?${q.toString()}`;
    },
    me: () => request(CFG.identityBase, '/authentication/me', { allowStatuses: [200, 401] }),
    logout: () =>
      request(CFG.identityBase, '/authentication/logout', {
        method: 'POST',
        allowStatuses: [200, 401],
      }),
  },

  campaigns: {
    list: (params) =>
      requestWithBaseFallback(CFG.projectBase, CFG.projectFallbackBase, `/campaigns${qs(params)}`),
    detail: (id) =>
      requestWithBaseFallback(CFG.projectBase, CFG.projectFallbackBase, `/campaigns/${id}`),
    create: (payload) =>
      requestWithBaseFallback(CFG.projectBase, CFG.projectFallbackBase, '/campaigns', {
        method: 'POST',
        body: payload,
      }),
    update: (id, payload) =>
      requestWithBaseFallback(CFG.projectBase, CFG.projectFallbackBase, `/campaigns/${id}`, {
        method: 'PUT',
        body: payload,
      }),
    archive: (id) =>
      requestWithBaseFallback(CFG.projectBase, CFG.projectFallbackBase, `/campaigns/${id}`, {
        method: 'DELETE',
      }),
  },

  projects: {
    listByCampaign: (campaignId, params) =>
      requestWithBaseFallback(
        CFG.projectBase,
        CFG.projectFallbackBase,
        `/campaigns/${campaignId}/projects${qs(params)}`
      ),
    detail: (projectId) =>
      requestWithBaseFallback(CFG.projectBase, CFG.projectFallbackBase, `/projects/${projectId}`),
    create: (campaignId, payload) =>
      requestWithBaseFallback(CFG.projectBase, CFG.projectFallbackBase, `/campaigns/${campaignId}/projects`, {
        method: 'POST',
        body: payload,
      }),
    update: (projectId, payload) =>
      requestWithBaseFallback(CFG.projectBase, CFG.projectFallbackBase, `/projects/${projectId}`, {
        method: 'PUT',
        body: payload,
      }),
    archive: (projectId) =>
      requestWithBaseFallback(CFG.projectBase, CFG.projectFallbackBase, `/projects/${projectId}`, {
        method: 'DELETE',
      }),
  },

  datasources: {
    listByProject: (projectId, params = {}) =>
      request(CFG.ingestBase, `/datasources${qs({ ...params, project_id: projectId })}`),
    detail: (datasourceId) => request(CFG.ingestBase, `/datasources/${datasourceId}`),
    create: (payload) => request(CFG.ingestBase, '/datasources', { method: 'POST', body: payload }),
    update: (datasourceId, payload) =>
      request(CFG.ingestBase, `/datasources/${datasourceId}`, { method: 'PUT', body: payload }),
    archive: (datasourceId) => request(CFG.ingestBase, `/datasources/${datasourceId}`, { method: 'DELETE' }),
  },

  targets: {
    list: (datasourceId, params = {}) =>
      request(CFG.ingestBase, `/datasources/${datasourceId}/targets${qs(params)}`),
    detail: (datasourceId, targetId) =>
      request(CFG.ingestBase, `/datasources/${datasourceId}/targets/${targetId}`),
    create: (datasourceId, targetTypePath, payload) =>
      request(CFG.ingestBase, `/datasources/${datasourceId}/targets/${targetTypePath}`, {
        method: 'POST',
        body: payload,
      }),
    update: (datasourceId, targetId, payload) =>
      request(CFG.ingestBase, `/datasources/${datasourceId}/targets/${targetId}`, {
        method: 'PUT',
        body: payload,
      }),
    remove: (datasourceId, targetId) =>
      request(CFG.ingestBase, `/datasources/${datasourceId}/targets/${targetId}`, {
        method: 'DELETE',
      }),
  },
};

export function formatApiError(err) {
  if (!(err instanceof ApiError)) {
    return String(err);
  }
  const info = err.details || {};
  return `${err.message}\n${pretty(info)}`;
}

export { ApiError };
