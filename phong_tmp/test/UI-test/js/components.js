export function escapeHtml(value) {
  return String(value == null ? '' : value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/\"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

export function pretty(value) {
  return JSON.stringify(value, null, 2);
}

export function showToast(message, kind = 'info') {
  const stack = document.getElementById('toast-stack');
  const item = document.createElement('div');
  item.className = `toast ${kind}`;
  item.textContent = message;
  stack.appendChild(item);
  setTimeout(() => {
    item.remove();
  }, 3600);
}

export function renderLoadingBlock(label = 'Loading...') {
  return `<div class="loading-block">${escapeHtml(label)}</div>`;
}

export function renderErrorBlock(message) {
  return `<div class="error-block">${escapeHtml(message)}</div>`;
}

export function statusBadge(value) {
  const safe = escapeHtml(value || '-');
  return `<span class="badge">${safe}</span>`;
}

export function openConfirm({ title, message }) {
  return window.confirm(`${title}\n\n${message}`);
}

export function toLocalDateTimeInput(value) {
  if (!value) return '';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '';
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  const hh = String(date.getHours()).padStart(2, '0');
  const mm = String(date.getMinutes()).padStart(2, '0');
  return `${y}-${m}-${d}T${hh}:${mm}`;
}

export function parseOptionalJson(text) {
  const raw = (text || '').trim();
  if (!raw) return undefined;
  return JSON.parse(raw);
}

export function parseValuesLines(text) {
  return String(text || '')
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean);
}

export function validateUrls(values) {
  for (const value of values) {
    try {
      const u = new URL(value);
      if (!u.protocol || !u.host) {
        return false;
      }
    } catch (_err) {
      return false;
    }
  }
  return true;
}

export function effectiveStatus(httpStatus, body) {
  if (
    httpStatus === 200 &&
    body &&
    typeof body === 'object' &&
    typeof body.error_code === 'number' &&
    body.error_code !== 0
  ) {
    return body.error_code;
  }
  return httpStatus;
}
