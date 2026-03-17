import { api, formatApiError } from '../api.js';
import { CFG, ENUMS } from '../config.js';
import { getState, setState } from '../store.js';
import {
  escapeHtml,
  openConfirm,
  pretty,
  renderErrorBlock,
  renderLoadingBlock,
  showToast,
  statusBadge,
  toLocalDateTimeInput,
} from '../components.js';

/**
 * @typedef {Object} CampaignFormState
 * @property {'create'|'edit'} mode
 * @property {boolean} open
 * @property {string|null} id
 * @property {string} name
 * @property {string} description
 * @property {string} startDate
 * @property {string} endDate
 * @property {string} status
 */

export function mountCampaignsPage(container) {
  const pageState = {
    loading: false,
    error: '',
    query: '',
    page: 1,
    limit: CFG.defaultPageSize,
    total: 0,
    selectedId: null,
    form: {
      mode: 'create',
      open: false,
      id: null,
      name: '',
      description: '',
      startDate: '',
      endDate: '',
      status: 'ACTIVE',
    },
  };

  function selectedCampaign() {
    const state = getState();
    return state.campaigns.find((item) => item.id === pageState.selectedId) || null;
  }

  function resetForm() {
    pageState.form = {
      mode: 'create',
      open: false,
      id: null,
      name: '',
      description: '',
      startDate: '',
      endDate: '',
      status: 'ACTIVE',
    };
  }

  function openCreateForm() {
    resetForm();
    pageState.form.open = true;
    render();
  }

  function openEditForm(id) {
    const item = getState().campaigns.find((c) => c.id === id);
    if (!item) return;
    pageState.form = {
      mode: 'edit',
      open: true,
      id,
      name: item.name || '',
      description: item.description || '',
      startDate: toLocalDateTimeInput(item.start_date),
      endDate: toLocalDateTimeInput(item.end_date),
      status: item.status || 'ACTIVE',
    };
    render();
  }

  async function loadCampaigns() {
    pageState.loading = true;
    pageState.error = '';
    render();

    try {
      const result = await api.campaigns.list({
        page: pageState.page,
        limit: pageState.limit,
        name: pageState.query || undefined,
      });

      const campaigns = (result.data && result.data.campaigns) || [];
      const paginator = (result.data && result.data.paginator) || {};
      pageState.total = paginator.total || campaigns.length || 0;

      if (campaigns.length && !pageState.selectedId) {
        pageState.selectedId = campaigns[0].id;
      }
      if (pageState.selectedId && !campaigns.some((item) => item.id === pageState.selectedId)) {
        pageState.selectedId = campaigns[0] ? campaigns[0].id : null;
      }

      setState({
        campaigns,
        selectedCampaignId: pageState.selectedId,
      });
    } catch (err) {
      pageState.error = formatApiError(err);
    } finally {
      pageState.loading = false;
      render();
    }
  }

  async function saveForm() {
    const payload = {
      name: pageState.form.name.trim(),
      description: pageState.form.description.trim(),
    };

    if (!payload.name) {
      showToast('Campaign name is required', 'error');
      return;
    }

    if (pageState.form.startDate) {
      payload.start_date = new Date(pageState.form.startDate).toISOString();
    }
    if (pageState.form.endDate) {
      payload.end_date = new Date(pageState.form.endDate).toISOString();
    }
    if (pageState.form.mode === 'edit') {
      payload.status = pageState.form.status;
    }

    try {
      if (pageState.form.mode === 'create') {
        const created = await api.campaigns.create(payload);
        const id = created.data && created.data.campaign && created.data.campaign.id;
        if (id) {
          pageState.selectedId = id;
        }
        showToast('Campaign created', 'success');
      } else {
        await api.campaigns.update(pageState.form.id, payload);
        pageState.selectedId = pageState.form.id;
        showToast('Campaign updated', 'success');
      }

      resetForm();
      await loadCampaigns();
    } catch (err) {
      showToast('Save campaign failed', 'error');
      pageState.error = formatApiError(err);
      render();
    }
  }

  async function archiveCampaign(id) {
    if (!openConfirm({ title: 'Archive Campaign', message: 'Archive this campaign now?' })) {
      return;
    }

    try {
      await api.campaigns.archive(id);
      showToast('Campaign archived', 'success');
      if (pageState.selectedId === id) {
        pageState.selectedId = null;
      }
      await loadCampaigns();
    } catch (err) {
      showToast('Archive campaign failed', 'error');
      pageState.error = formatApiError(err);
      render();
    }
  }

  function renderListRows() {
    const state = getState();
    if (!state.campaigns.length) {
      return '<tr><td colspan="5" class="muted-cell">No campaigns</td></tr>';
    }

    return state.campaigns
      .map((item) => {
        const isSelected = item.id === pageState.selectedId ? 'is-selected' : '';
        return `
          <tr class="${isSelected}">
            <td>${escapeHtml(item.name)}</td>
            <td>${statusBadge(item.status)}</td>
            <td>${escapeHtml(item.start_date || '-')}</td>
            <td>${escapeHtml(item.end_date || '-')}</td>
            <td>
              <div class="row-actions">
                <button data-action="select" data-id="${item.id}">View</button>
                <button data-action="edit" data-id="${item.id}">Edit</button>
                <button class="danger" data-action="archive" data-id="${item.id}">Archive</button>
              </div>
            </td>
          </tr>
        `;
      })
      .join('');
  }

  function renderModal() {
    if (!pageState.form.open) {
      return '';
    }

    const title = pageState.form.mode === 'create' ? 'Create Campaign' : 'Edit Campaign';
    const statusField =
      pageState.form.mode === 'edit'
        ? `
          <label>
            <span>Status</span>
            <select id="campaign-status">
              ${ENUMS.campaignStatus
                .map(
                  (s) => `<option value="${s}" ${s === pageState.form.status ? 'selected' : ''}>${s}</option>`
                )
                .join('')}
            </select>
          </label>
        `
        : '';

    return `
      <div class="modal-backdrop" data-action="close-modal">
        <div class="modal" role="dialog" aria-modal="true" aria-label="Campaign form">
          <div class="modal-head">
            <h3>${title}</h3>
            <button class="ghost" data-action="close-modal">Close</button>
          </div>
          <div class="modal-body">
            <label>
              <span>Name *</span>
              <input id="campaign-name" type="text" value="${escapeHtml(pageState.form.name)}">
            </label>
            <label>
              <span>Description</span>
              <textarea id="campaign-description" rows="3">${escapeHtml(pageState.form.description)}</textarea>
            </label>
            <div class="grid two">
              <label>
                <span>Start Date</span>
                <input id="campaign-start" type="datetime-local" value="${escapeHtml(pageState.form.startDate)}">
              </label>
              <label>
                <span>End Date</span>
                <input id="campaign-end" type="datetime-local" value="${escapeHtml(pageState.form.endDate)}">
              </label>
            </div>
            ${statusField}
          </div>
          <div class="modal-foot">
            <button class="secondary" data-action="close-modal">Cancel</button>
            <button class="primary" data-action="save-form">Save</button>
          </div>
        </div>
      </div>
    `;
  }

  function render() {
    const state = getState();
    const selected = selectedCampaign();
    const totalPages = Math.max(1, Math.ceil(pageState.total / pageState.limit));

    container.innerHTML = `
      <section class="page-head">
        <div>
          <h2>Campaign Management</h2>
          <p>Create and manage campaign containers for projects.</p>
        </div>
        <button class="primary" id="create-campaign-btn">Create Campaign</button>
      </section>

      <section class="card panel-grid">
        <div class="toolbar">
          <input id="campaign-search" type="text" placeholder="Search campaign name" value="${escapeHtml(
            pageState.query
          )}">
          <button class="secondary" id="campaign-search-btn">Search</button>
          <button class="secondary" id="campaign-refresh-btn">Refresh</button>
        </div>

        ${pageState.loading ? renderLoadingBlock('Loading campaigns...') : ''}
        ${pageState.error ? renderErrorBlock(pageState.error) : ''}

        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Status</th>
                <th>Start</th>
                <th>End</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              ${!pageState.loading ? renderListRows() : ''}
            </tbody>
          </table>
        </div>

        <div class="pager">
          <button class="secondary" id="campaign-prev" ${pageState.page <= 1 ? 'disabled' : ''}>Prev</button>
          <span>Page ${pageState.page} / ${totalPages}</span>
          <button class="secondary" id="campaign-next" ${pageState.page >= totalPages ? 'disabled' : ''}>Next</button>
        </div>
      </section>

      <section class="card detail-card">
        <div class="detail-head">
          <h3>Campaign Detail</h3>
          <span class="mono">${escapeHtml(pageState.selectedId || '-')}</span>
        </div>
        <pre>${selected ? escapeHtml(pretty(selected)) : 'Select a campaign row to inspect detail.'}</pre>
      </section>

      ${renderModal()}
    `;

    bindEvents();
  }

  function bindEvents() {
    const createBtn = container.querySelector('#create-campaign-btn');
    if (createBtn) createBtn.addEventListener('click', openCreateForm);

    const searchBtn = container.querySelector('#campaign-search-btn');
    if (searchBtn) {
      searchBtn.addEventListener('click', () => {
        const input = container.querySelector('#campaign-search');
        pageState.query = input.value.trim();
        pageState.page = 1;
        loadCampaigns();
      });
    }

    const refreshBtn = container.querySelector('#campaign-refresh-btn');
    if (refreshBtn) refreshBtn.addEventListener('click', loadCampaigns);

    const prevBtn = container.querySelector('#campaign-prev');
    if (prevBtn) {
      prevBtn.addEventListener('click', () => {
        if (pageState.page > 1) {
          pageState.page -= 1;
          loadCampaigns();
        }
      });
    }

    const nextBtn = container.querySelector('#campaign-next');
    if (nextBtn) {
      nextBtn.addEventListener('click', () => {
        pageState.page += 1;
        loadCampaigns();
      });
    }

    container.querySelectorAll('[data-action="select"]').forEach((btn) => {
      btn.addEventListener('click', () => {
        pageState.selectedId = btn.getAttribute('data-id');
        setState({ selectedCampaignId: pageState.selectedId });
        render();
      });
    });

    container.querySelectorAll('[data-action="edit"]').forEach((btn) => {
      btn.addEventListener('click', () => openEditForm(btn.getAttribute('data-id')));
    });

    container.querySelectorAll('[data-action="archive"]').forEach((btn) => {
      btn.addEventListener('click', () => archiveCampaign(btn.getAttribute('data-id')));
    });

    container.querySelectorAll('[data-action="close-modal"]').forEach((btn) => {
      btn.addEventListener('click', (event) => {
        if (event.target === btn || btn.classList.contains('ghost') || btn.classList.contains('secondary')) {
          pageState.form.open = false;
          render();
        }
      });
    });

    const saveBtn = container.querySelector('[data-action="save-form"]');
    if (saveBtn) {
      saveBtn.addEventListener('click', () => {
        pageState.form.name = container.querySelector('#campaign-name').value;
        pageState.form.description = container.querySelector('#campaign-description').value;
        pageState.form.startDate = container.querySelector('#campaign-start').value;
        pageState.form.endDate = container.querySelector('#campaign-end').value;
        const statusInput = container.querySelector('#campaign-status');
        if (statusInput) {
          pageState.form.status = statusInput.value;
        }
        saveForm();
      });
    }
  }

  loadCampaigns();

  return () => {
    container.innerHTML = '';
  };
}
