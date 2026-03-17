import { api, formatApiError } from '../api.js';
import { CFG, ENUMS } from '../config.js';
import { getState, setState } from '../store.js';
import {
  escapeHtml,
  openConfirm,
  parseOptionalJson,
  parseValuesLines,
  pretty,
  renderErrorBlock,
  renderLoadingBlock,
  showToast,
  statusBadge,
  validateUrls,
} from '../components.js';

/**
 * @typedef {Object} DatasourceFormState
 * @property {'create'|'edit'} mode
 * @property {boolean} open
 * @property {string|null} id
 * @property {string} name
 * @property {string} description
 * @property {string} source_type
 * @property {string} source_category
 * @property {string} crawl_mode
 * @property {string} crawl_interval_minutes
 * @property {string} config
 * @property {string} account_ref
 */

/**
 * @typedef {Object} TargetDraft
 * @property {string} id
 * @property {'keywords'|'profiles'|'posts'} type
 * @property {string} label
 * @property {string} values
 * @property {string} priority
 * @property {string} interval
 * @property {boolean} is_active
 * @property {string} platform_meta
 */

/**
 * @typedef {Object} PipelineCreateResult
 * @property {string|null} projectId
 * @property {string|null} datasourceId
 * @property {string[]} targetIds
 * @property {string|null} failedStep
 * @property {string|null} error
 */

function makeId(prefix) {
  return `${prefix}_${Math.random().toString(36).slice(2, 10)}`;
}

function defaultTargetDraft() {
  return {
    id: makeId('draft'),
    type: 'keywords',
    label: '',
    values: '',
    priority: '1',
    interval: '11',
    is_active: true,
    platform_meta: '',
  };
}

function defaultWizardState() {
  return {
    open: false,
    step: 1,
    submitting: false,
    error: '',
    success: '',
    project: {
      name: '',
      description: '',
      brand: '',
      entity_type: 'product',
      entity_name: '',
    },
    datasource: {
      name: '',
      description: '',
      source_type: 'TIKTOK',
      source_category: 'CRAWL',
      crawl_mode: 'NORMAL',
      crawl_interval_minutes: '11',
      config: '',
      account_ref: '',
    },
    targets: [defaultTargetDraft()],
    pipeline: {
      projectId: null,
      datasourceId: null,
      targetIds: [],
      failedStep: null,
      error: null,
    },
  };
}

function defaultProjectForm() {
  return {
    open: false,
    mode: 'edit',
    id: null,
    name: '',
    description: '',
    brand: '',
    entity_type: 'product',
    entity_name: '',
    status: 'ACTIVE',
  };
}

function defaultDatasourceForm() {
  return {
    open: false,
    mode: 'create',
    id: null,
    name: '',
    description: '',
    source_type: 'TIKTOK',
    source_category: 'CRAWL',
    crawl_mode: 'NORMAL',
    crawl_interval_minutes: '11',
    config: '',
    account_ref: '',
  };
}

function defaultTargetForm() {
  return {
    open: false,
    mode: 'create',
    id: null,
    type: 'keywords',
    label: '',
    values: '',
    priority: '1',
    interval: '11',
    is_active: true,
    platform_meta: '',
  };
}

function mapTargetTypeToPath(targetType) {
  if (targetType === 'KEYWORD' || targetType === 'keywords') return 'keywords';
  if (targetType === 'PROFILE' || targetType === 'profiles') return 'profiles';
  return 'posts';
}

export function mountProjectsPage(container) {
  const pageState = {
    campaignLoading: false,
    campaignError: '',
    projectLoading: false,
    projectError: '',
    projectQuery: '',
    page: 1,
    limit: CFG.defaultPageSize,
    total: 0,
    selectedCampaignId: null,
    selectedProjectId: null,
    projectForm: defaultProjectForm(),
    wizard: defaultWizardState(),
    datasource: {
      loading: false,
      error: '',
      selectedId: null,
      form: defaultDatasourceForm(),
      detail: null,
    },
    target: {
      loading: false,
      error: '',
      form: defaultTargetForm(),
      detail: null,
    },
    activeTab: 'datasources',
  };

  function getSelectedProject() {
    return getState().projects.find((item) => item.id === pageState.selectedProjectId) || null;
  }

  function getSelectedDatasource() {
    return getState().datasources.find((item) => item.id === pageState.datasource.selectedId) || null;
  }

  async function loadCampaignOptions() {
    pageState.campaignLoading = true;
    pageState.campaignError = '';
    render();

    try {
      const result = await api.campaigns.list({ page: 1, limit: 100 });
      const campaigns = (result.data && result.data.campaigns) || [];

      if (!pageState.selectedCampaignId && campaigns.length) {
        pageState.selectedCampaignId = campaigns[0].id;
      }
      if (
        pageState.selectedCampaignId &&
        !campaigns.some((item) => item.id === pageState.selectedCampaignId)
      ) {
        pageState.selectedCampaignId = campaigns[0] ? campaigns[0].id : null;
      }

      setState({
        campaigns,
        selectedCampaignId: pageState.selectedCampaignId,
      });
    } catch (err) {
      pageState.campaignError = formatApiError(err);
    } finally {
      pageState.campaignLoading = false;
      render();
    }
  }

  async function loadProjects() {
    if (!pageState.selectedCampaignId) {
      setState({ projects: [] });
      pageState.total = 0;
      render();
      return;
    }

    pageState.projectLoading = true;
    pageState.projectError = '';
    render();

    try {
      const result = await api.projects.listByCampaign(pageState.selectedCampaignId, {
        page: pageState.page,
        limit: pageState.limit,
        name: pageState.projectQuery || undefined,
      });

      const projects = (result.data && result.data.projects) || [];
      const paginator = (result.data && result.data.paginator) || {};
      pageState.total = paginator.total || projects.length || 0;

      if (projects.length && !pageState.selectedProjectId) {
        pageState.selectedProjectId = projects[0].id;
      }
      if (
        pageState.selectedProjectId &&
        !projects.some((item) => item.id === pageState.selectedProjectId)
      ) {
        pageState.selectedProjectId = projects[0] ? projects[0].id : null;
      }

      setState({
        projects,
        selectedProjectId: pageState.selectedProjectId,
      });

      if (pageState.selectedProjectId) {
        await loadDatasources();
      } else {
        setState({ datasources: [], targets: [] });
        pageState.datasource.selectedId = null;
      }
    } catch (err) {
      pageState.projectError = formatApiError(err);
    } finally {
      pageState.projectLoading = false;
      render();
    }
  }

  async function loadDatasources() {
    if (!pageState.selectedProjectId) {
      setState({ datasources: [] });
      pageState.datasource.selectedId = null;
      return;
    }

    pageState.datasource.loading = true;
    pageState.datasource.error = '';
    render();

    try {
      const result = await api.datasources.listByProject(pageState.selectedProjectId, {
        page: 1,
        limit: 100,
      });
      const datasources = (result.data && result.data.data_sources) || [];

      if (datasources.length && !pageState.datasource.selectedId) {
        pageState.datasource.selectedId = datasources[0].id;
      }
      if (
        pageState.datasource.selectedId &&
        !datasources.some((item) => item.id === pageState.datasource.selectedId)
      ) {
        pageState.datasource.selectedId = datasources[0] ? datasources[0].id : null;
      }

      setState({
        datasources,
        selectedDatasourceId: pageState.datasource.selectedId,
      });

      if (pageState.datasource.selectedId) {
        await loadTargets();
      } else {
        setState({ targets: [] });
      }
    } catch (err) {
      pageState.datasource.error = formatApiError(err);
    } finally {
      pageState.datasource.loading = false;
      render();
    }
  }

  async function loadTargets() {
    if (!pageState.datasource.selectedId) {
      setState({ targets: [] });
      return;
    }

    pageState.target.loading = true;
    pageState.target.error = '';
    render();

    try {
      const result = await api.targets.list(pageState.datasource.selectedId, {});
      const targets = (result.data && result.data.targets) || [];
      setState({ targets });
    } catch (err) {
      pageState.target.error = formatApiError(err);
    } finally {
      pageState.target.loading = false;
      render();
    }
  }

  function openProjectEditForm(id) {
    const item = getState().projects.find((p) => p.id === id);
    if (!item) return;
    pageState.projectForm = {
      open: true,
      mode: 'edit',
      id,
      name: item.name || '',
      description: item.description || '',
      brand: item.brand || '',
      entity_type: item.entity_type || 'product',
      entity_name: item.entity_name || '',
      status: item.status || 'ACTIVE',
    };
    render();
  }

  function closeProjectEditForm() {
    pageState.projectForm = defaultProjectForm();
    render();
  }

  async function saveProjectEdit() {
    const payload = {
      name: pageState.projectForm.name.trim(),
      description: pageState.projectForm.description.trim(),
      brand: pageState.projectForm.brand.trim(),
      entity_type: pageState.projectForm.entity_type,
      entity_name: pageState.projectForm.entity_name.trim(),
      status: pageState.projectForm.status,
    };

    if (!payload.name || !payload.entity_type || !payload.entity_name) {
      showToast('Project name/entity fields are required', 'error');
      return;
    }

    try {
      await api.projects.update(pageState.projectForm.id, payload);
      showToast('Project updated', 'success');
      closeProjectEditForm();
      await loadProjects();
    } catch (err) {
      pageState.projectError = formatApiError(err);
      showToast('Project update failed', 'error');
      render();
    }
  }

  async function archiveProject(id) {
    if (!openConfirm({ title: 'Archive Project', message: 'Archive this project now?' })) {
      return;
    }

    try {
      await api.projects.archive(id);
      showToast('Project archived', 'success');
      if (pageState.selectedProjectId === id) {
        pageState.selectedProjectId = null;
        pageState.datasource.selectedId = null;
      }
      await loadProjects();
    } catch (err) {
      pageState.projectError = formatApiError(err);
      showToast('Project archive failed', 'error');
      render();
    }
  }

  function openDatasourceForm(mode, id = null) {
    if (!pageState.selectedProjectId) {
      showToast('Select project first', 'error');
      return;
    }

    if (mode === 'edit') {
      const item = getState().datasources.find((d) => d.id === id);
      if (!item) return;
      pageState.datasource.form = {
        open: true,
        mode,
        id,
        name: item.name || '',
        description: item.description || '',
        source_type: item.source_type || 'TIKTOK',
        source_category: item.source_category || 'CRAWL',
        crawl_mode: item.crawl_mode || 'NORMAL',
        crawl_interval_minutes: String(item.crawl_interval_minutes || 11),
        config: item.config ? pretty(item.config) : '',
        account_ref: item.account_ref ? pretty(item.account_ref) : '',
      };
    } else {
      pageState.datasource.form = defaultDatasourceForm();
      pageState.datasource.form.open = true;
      pageState.datasource.form.mode = 'create';
    }

    render();
  }

  function closeDatasourceForm() {
    pageState.datasource.form = defaultDatasourceForm();
    render();
  }

  async function saveDatasourceForm() {
    const form = pageState.datasource.form;
    const payload = {
      name: form.name.trim(),
      description: form.description.trim(),
    };

    if (!payload.name) {
      showToast('Datasource name is required', 'error');
      return;
    }

    try {
      if (form.mode === 'create') {
        payload.project_id = pageState.selectedProjectId;
        payload.source_type = form.source_type;
        payload.source_category = form.source_category;

        if (form.source_category === 'CRAWL') {
          const interval = Number(form.crawl_interval_minutes);
          if (!Number.isFinite(interval) || interval <= 0) {
            showToast('Crawl interval must be > 0', 'error');
            return;
          }
          payload.crawl_mode = form.crawl_mode;
          payload.crawl_interval_minutes = interval;
        }
      }

      if (form.config.trim()) {
        payload.config = parseOptionalJson(form.config);
      }
      if (form.account_ref.trim()) {
        payload.account_ref = parseOptionalJson(form.account_ref);
      }

      if (form.mode === 'create') {
        const result = await api.datasources.create(payload);
        const createdId = result.data && result.data.data_source && result.data.data_source.id;
        if (createdId) {
          pageState.datasource.selectedId = createdId;
        }
        showToast('Datasource created', 'success');
      } else {
        await api.datasources.update(form.id, payload);
        pageState.datasource.selectedId = form.id;
        showToast('Datasource updated', 'success');
      }

      closeDatasourceForm();
      await loadDatasources();
    } catch (err) {
      pageState.datasource.error = formatApiError(err);
      showToast('Save datasource failed', 'error');
      render();
    }
  }

  async function archiveDatasource(id) {
    if (!openConfirm({ title: 'Archive Datasource', message: 'Archive this datasource now?' })) {
      return;
    }

    try {
      await api.datasources.archive(id);
      showToast('Datasource archived', 'success');
      if (pageState.datasource.selectedId === id) {
        pageState.datasource.selectedId = null;
      }
      await loadDatasources();
    } catch (err) {
      pageState.datasource.error = formatApiError(err);
      showToast('Archive datasource failed', 'error');
      render();
    }
  }

  function openTargetForm(mode, id = null) {
    if (!pageState.datasource.selectedId) {
      showToast('Select datasource first', 'error');
      return;
    }

    if (mode === 'edit') {
      const item = getState().targets.find((t) => t.id === id);
      if (!item) return;
      pageState.target.form = {
        open: true,
        mode,
        id,
        type: mapTargetTypeToPath(item.target_type),
        label: item.label || '',
        values: Array.isArray(item.values) ? item.values.join('\n') : '',
        priority: String(item.priority ?? 1),
        interval: String(item.crawl_interval_minutes ?? 11),
        is_active: Boolean(item.is_active),
        platform_meta: item.platform_meta ? pretty(item.platform_meta) : '',
      };
    } else {
      pageState.target.form = defaultTargetForm();
      pageState.target.form.open = true;
    }

    render();
  }

  function closeTargetForm() {
    pageState.target.form = defaultTargetForm();
    render();
  }

  async function saveTargetForm() {
    const form = pageState.target.form;
    const values = parseValuesLines(form.values);

    if (!values.length) {
      showToast('Target values are required', 'error');
      return;
    }

    if ((form.type === 'profiles' || form.type === 'posts') && !validateUrls(values)) {
      showToast('Profile/Post target values must be URLs', 'error');
      return;
    }

    const interval = Number(form.interval);
    if (!Number.isFinite(interval) || interval <= 0) {
      showToast('Target interval must be > 0', 'error');
      return;
    }

    const payload = {
      values,
      label: form.label.trim(),
      is_active: form.is_active,
      priority: Number(form.priority || 1),
      crawl_interval_minutes: interval,
    };

    try {
      if (form.platform_meta.trim()) {
        payload.platform_meta = parseOptionalJson(form.platform_meta);
      }

      if (form.mode === 'create') {
        await api.targets.create(pageState.datasource.selectedId, form.type, payload);
        showToast('Target created', 'success');
      } else {
        await api.targets.update(pageState.datasource.selectedId, form.id, payload);
        showToast('Target updated', 'success');
      }

      closeTargetForm();
      await loadTargets();
    } catch (err) {
      pageState.target.error = formatApiError(err);
      showToast('Save target failed', 'error');
      render();
    }
  }

  async function deleteTarget(id) {
    if (!openConfirm({ title: 'Delete Target', message: 'Delete this target now?' })) {
      return;
    }

    try {
      await api.targets.remove(pageState.datasource.selectedId, id);
      showToast('Target deleted', 'success');
      await loadTargets();
    } catch (err) {
      pageState.target.error = formatApiError(err);
      showToast('Delete target failed', 'error');
      render();
    }
  }

  function openWizard() {
    if (!pageState.selectedCampaignId) {
      showToast('Select campaign first', 'error');
      return;
    }
    pageState.wizard = defaultWizardState();
    pageState.wizard.open = true;
    render();
  }

  function closeWizard() {
    pageState.wizard = defaultWizardState();
    render();
  }

  function wizardValidateStep(step) {
    const w = pageState.wizard;

    if (step === 1) {
      if (!w.project.name.trim() || !w.project.entity_type || !w.project.entity_name.trim()) {
        w.error = 'Step 1: project name/entity type/entity name are required';
        return false;
      }
    }

    if (step === 2) {
      if (!w.datasource.name.trim() || !w.datasource.source_type || !w.datasource.source_category) {
        w.error = 'Step 2: datasource basic fields are required';
        return false;
      }
      if (w.datasource.source_category === 'CRAWL') {
        const interval = Number(w.datasource.crawl_interval_minutes);
        if (!w.datasource.crawl_mode || !Number.isFinite(interval) || interval <= 0) {
          w.error = 'Step 2: crawl mode and interval > 0 are required for CRAWL source';
          return false;
        }
      }
    }

    if (step === 3) {
      if (!w.targets.length) {
        w.error = 'Step 3: at least one target is required';
        return false;
      }
      for (const target of w.targets) {
        const values = parseValuesLines(target.values);
        const interval = Number(target.interval);
        if (!values.length) {
          w.error = 'Step 3: each target must have values';
          return false;
        }
        if (!Number.isFinite(interval) || interval <= 0) {
          w.error = 'Step 3: target interval must be > 0';
          return false;
        }
        if ((target.type === 'profiles' || target.type === 'posts') && !validateUrls(values)) {
          w.error = 'Step 3: profiles/posts target values must be URLs';
          return false;
        }
      }
    }

    w.error = '';
    return true;
  }

  function wizardNext() {
    if (!wizardValidateStep(pageState.wizard.step)) {
      showToast(pageState.wizard.error, 'error');
      render();
      return;
    }
    pageState.wizard.step = Math.min(5, pageState.wizard.step + 1);
    pageState.wizard.error = '';
    render();
  }

  function wizardPrev() {
    pageState.wizard.step = Math.max(1, pageState.wizard.step - 1);
    pageState.wizard.error = '';
    render();
  }

  async function runPipelineCreate() {
    const w = pageState.wizard;
    if (!wizardValidateStep(1) || !wizardValidateStep(2) || !wizardValidateStep(3)) {
      showToast(w.error || 'Wizard validation failed', 'error');
      render();
      return;
    }

    w.submitting = true;
    w.error = '';
    w.success = '';
    w.pipeline = {
      projectId: null,
      datasourceId: null,
      targetIds: [],
      failedStep: null,
      error: null,
    };
    render();

    try {
      const createProjectPayload = {
        name: w.project.name.trim(),
        description: w.project.description.trim(),
        brand: w.project.brand.trim(),
        entity_type: w.project.entity_type,
        entity_name: w.project.entity_name.trim(),
      };

      const projectRes = await api.projects.create(pageState.selectedCampaignId, createProjectPayload);
      const projectId = projectRes.data && projectRes.data.project && projectRes.data.project.id;
      if (!projectId) {
        throw new Error('Project ID missing from create response');
      }
      w.pipeline.projectId = projectId;

      const datasourcePayload = {
        project_id: projectId,
        name: w.datasource.name.trim(),
        description: w.datasource.description.trim(),
        source_type: w.datasource.source_type,
        source_category: w.datasource.source_category,
      };

      if (w.datasource.source_category === 'CRAWL') {
        datasourcePayload.crawl_mode = w.datasource.crawl_mode;
        datasourcePayload.crawl_interval_minutes = Number(w.datasource.crawl_interval_minutes);
      }
      if (w.datasource.config.trim()) {
        datasourcePayload.config = parseOptionalJson(w.datasource.config);
      }
      if (w.datasource.account_ref.trim()) {
        datasourcePayload.account_ref = parseOptionalJson(w.datasource.account_ref);
      }

      const datasourceRes = await api.datasources.create(datasourcePayload);
      const datasourceId = datasourceRes.data && datasourceRes.data.data_source && datasourceRes.data.data_source.id;
      if (!datasourceId) {
        throw new Error('Datasource ID missing from create response');
      }
      w.pipeline.datasourceId = datasourceId;

      for (const draft of w.targets) {
        const targetPayload = {
          values: parseValuesLines(draft.values),
          label: draft.label.trim(),
          is_active: draft.is_active,
          priority: Number(draft.priority || 1),
          crawl_interval_minutes: Number(draft.interval),
        };
        if (draft.platform_meta.trim()) {
          targetPayload.platform_meta = parseOptionalJson(draft.platform_meta);
        }

        const targetRes = await api.targets.create(datasourceId, draft.type, targetPayload);
        const targetId = targetRes.data && targetRes.data.target && targetRes.data.target.id;
        if (!targetId) {
          throw new Error(`Target ID missing from create response for draft ${draft.id}`);
        }
        w.pipeline.targetIds.push(targetId);
      }

      w.success = 'Pipeline created successfully: project, datasource, and targets are ready.';
      showToast('Wizard pipeline created successfully', 'success');
      w.step = 5;

      pageState.selectedProjectId = projectId;
      pageState.datasource.selectedId = datasourceId;

      await loadProjects();
      await loadDatasources();
      await loadTargets();
    } catch (err) {
      w.pipeline.failedStep = w.pipeline.datasourceId
        ? 'create_target'
        : w.pipeline.projectId
        ? 'create_datasource'
        : 'create_project';
      w.pipeline.error = formatApiError(err);
      w.error = `Pipeline failed at ${w.pipeline.failedStep}`;
      showToast('Wizard pipeline failed', 'error');
      w.step = 5;
    } finally {
      w.submitting = false;
      render();
    }
  }

  async function cleanupCreatedEntity(kind, id) {
    if (!id) return;
    try {
      if (kind === 'project') {
        await api.projects.archive(id);
      } else if (kind === 'datasource') {
        await api.datasources.archive(id);
      }
      showToast(`${kind} cleanup success`, 'success');
      if (kind === 'project') {
        pageState.wizard.pipeline.projectId = null;
      }
      if (kind === 'datasource') {
        pageState.wizard.pipeline.datasourceId = null;
      }
      render();
    } catch (err) {
      showToast(`${kind} cleanup failed`, 'error');
      pageState.wizard.error = formatApiError(err);
      render();
    }
  }

  async function cleanupTarget(targetId) {
    const datasourceId = pageState.wizard.pipeline.datasourceId;
    if (!datasourceId || !targetId) return;
    try {
      await api.targets.remove(datasourceId, targetId);
      pageState.wizard.pipeline.targetIds = pageState.wizard.pipeline.targetIds.filter((id) => id !== targetId);
      showToast('target cleanup success', 'success');
      render();
    } catch (err) {
      showToast('target cleanup failed', 'error');
      pageState.wizard.error = formatApiError(err);
      render();
    }
  }

  function renderCampaignSelector() {
    const campaigns = getState().campaigns;

    if (pageState.campaignLoading) {
      return '<div class="selector-wrap">Loading campaigns...</div>';
    }

    if (pageState.campaignError) {
      return `<div class="selector-wrap">${renderErrorBlock(pageState.campaignError)}</div>`;
    }

    return `
      <div class="selector-wrap">
        <label>
          <span>Campaign</span>
          <select id="project-campaign-select">
            ${campaigns
              .map(
                (c) =>
                  `<option value="${c.id}" ${c.id === pageState.selectedCampaignId ? 'selected' : ''}>${escapeHtml(
                    c.name
                  )}</option>`
              )
              .join('')}
          </select>
        </label>
      </div>
    `;
  }

  function renderProjectRows() {
    const projects = getState().projects;
    if (!projects.length) {
      return '<tr><td colspan="5" class="muted-cell">No projects</td></tr>';
    }

    return projects
      .map((item) => {
        const selected = item.id === pageState.selectedProjectId ? 'is-selected' : '';
        return `
          <tr class="${selected}">
            <td>${escapeHtml(item.name)}</td>
            <td>${escapeHtml(item.entity_type || '-')}</td>
            <td>${statusBadge(item.status)}</td>
            <td>${escapeHtml(item.updated_at || '-')}</td>
            <td>
              <div class="row-actions">
                <button data-action="project-select" data-id="${item.id}">View</button>
                <button data-action="project-edit" data-id="${item.id}">Edit</button>
                <button class="danger" data-action="project-archive" data-id="${item.id}">Archive</button>
              </div>
            </td>
          </tr>
        `;
      })
      .join('');
  }

  function renderDatasourceRows() {
    const datasources = getState().datasources;
    if (!datasources.length) {
      return '<tr><td colspan="5" class="muted-cell">No datasources</td></tr>';
    }

    return datasources
      .map((item) => {
        const selected = item.id === pageState.datasource.selectedId ? 'is-selected' : '';
        return `
          <tr class="${selected}">
            <td>${escapeHtml(item.name)}</td>
            <td>${escapeHtml(item.source_type)}</td>
            <td>${statusBadge(item.status)}</td>
            <td>${escapeHtml(item.crawl_mode || '-')}</td>
            <td>
              <div class="row-actions">
                <button data-action="datasource-select" data-id="${item.id}">View</button>
                <button data-action="datasource-edit" data-id="${item.id}">Edit</button>
                <button class="danger" data-action="datasource-archive" data-id="${item.id}">Archive</button>
              </div>
            </td>
          </tr>
        `;
      })
      .join('');
  }

  function renderTargetRows() {
    const targets = getState().targets;
    if (!targets.length) {
      return '<tr><td colspan="5" class="muted-cell">No targets</td></tr>';
    }

    return targets
      .map((item) => {
        return `
          <tr>
            <td>${escapeHtml(item.target_type)}</td>
            <td>${escapeHtml(item.label || '-')}</td>
            <td>${escapeHtml((item.values || []).slice(0, 2).join(', '))}</td>
            <td>${escapeHtml(String(item.crawl_interval_minutes || '-'))}</td>
            <td>
              <div class="row-actions">
                <button data-action="target-edit" data-id="${item.id}">Edit</button>
                <button class="danger" data-action="target-delete" data-id="${item.id}">Delete</button>
              </div>
            </td>
          </tr>
        `;
      })
      .join('');
  }

  function renderConfigTabs() {
    return `
      <div class="tabs">
        <button
          class="tab-btn ${pageState.activeTab === 'datasources' ? 'active' : ''}"
          data-action="switch-tab"
          data-tab="datasources"
        >
          Datasources
        </button>
        <button
          class="tab-btn ${pageState.activeTab === 'targets' ? 'active' : ''}"
          data-action="switch-tab"
          data-tab="targets"
        >
          Targets
        </button>
      </div>
    `;
  }

  function renderDatasourcePanel(selectedDatasource) {
    return `
      <div>
        <div class="panel-sub-head">
          <h3>Datasources</h3>
          <div class="row-actions">
            <button class="secondary" id="ds-create-btn">Create Datasource</button>
            <button class="secondary" id="ds-refresh-btn">Refresh</button>
          </div>
        </div>
        ${pageState.datasource.loading ? renderLoadingBlock('Loading datasources...') : ''}
        ${pageState.datasource.error ? renderErrorBlock(pageState.datasource.error) : ''}
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Type</th>
                <th>Status</th>
                <th>Mode</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>${!pageState.datasource.loading ? renderDatasourceRows() : ''}</tbody>
          </table>
        </div>
        <div class="detail-mini">
          <h4>Selected Datasource</h4>
          <pre>${selectedDatasource ? escapeHtml(pretty(selectedDatasource)) : 'Select datasource row first.'}</pre>
        </div>
      </div>
    `;
  }

  function renderTargetPanel() {
    const isDatasourceSelected = Boolean(pageState.datasource.selectedId);
    return `
      <div>
        <div class="panel-sub-head">
          <h3>Crawl Targets</h3>
          <div class="row-actions">
            <button class="secondary" id="target-create-btn" ${!isDatasourceSelected ? 'disabled' : ''}>Create Target</button>
            <button class="secondary" id="target-refresh-btn" ${!isDatasourceSelected ? 'disabled' : ''}>Refresh</button>
          </div>
        </div>
        ${pageState.target.loading ? renderLoadingBlock('Loading targets...') : ''}
        ${pageState.target.error ? renderErrorBlock(pageState.target.error) : ''}
        ${
          isDatasourceSelected
            ? `
          <div class="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Type</th>
                  <th>Label</th>
                  <th>Values</th>
                  <th>Interval</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>${!pageState.target.loading ? renderTargetRows() : ''}</tbody>
            </table>
          </div>
          `
            : '<div class="loading-block">Select a datasource first to view and manage targets.</div>'
        }
      </div>
    `;
  }

  function renderProjectEditModal() {
    if (!pageState.projectForm.open) return '';

    const f = pageState.projectForm;

    return `
      <div class="modal-backdrop" data-action="project-modal-close">
        <div class="modal" role="dialog" aria-modal="true">
          <div class="modal-head">
            <h3>Edit Project</h3>
            <button class="ghost" data-action="project-modal-close">Close</button>
          </div>
          <div class="modal-body">
            <div class="grid two">
              <label><span>Name *</span><input id="project-form-name" type="text" value="${escapeHtml(f.name)}"></label>
              <label><span>Brand</span><input id="project-form-brand" type="text" value="${escapeHtml(f.brand)}"></label>
            </div>
            <div class="grid two">
              <label>
                <span>Entity Type *</span>
                <select id="project-form-entity-type">
                  ${ENUMS.entityType
                    .map((item) => `<option value="${item}" ${item === f.entity_type ? 'selected' : ''}>${item}</option>`)
                    .join('')}
                </select>
              </label>
              <label><span>Entity Name *</span><input id="project-form-entity-name" type="text" value="${escapeHtml(
                f.entity_name
              )}"></label>
            </div>
            <label><span>Description</span><textarea id="project-form-description" rows="3">${escapeHtml(
              f.description
            )}</textarea></label>
            <label>
              <span>Status</span>
              <select id="project-form-status">
                ${ENUMS.projectStatus
                  .map((item) => `<option value="${item}" ${item === f.status ? 'selected' : ''}>${item}</option>`)
                  .join('')}
              </select>
            </label>
          </div>
          <div class="modal-foot">
            <button class="secondary" data-action="project-modal-close">Cancel</button>
            <button class="primary" data-action="project-save">Save</button>
          </div>
        </div>
      </div>
    `;
  }

  function renderDatasourceModal() {
    if (!pageState.datasource.form.open) return '';
    const f = pageState.datasource.form;
    const title = f.mode === 'create' ? 'Create Datasource' : 'Edit Datasource';
    const createOnly =
      f.mode === 'create'
        ? `
        <div class="grid three">
          <label>
            <span>Source Type</span>
            <select id="ds-form-source-type">${ENUMS.sourceType
              .map((it) => `<option value="${it}" ${it === f.source_type ? 'selected' : ''}>${it}</option>`)
              .join('')}</select>
          </label>
          <label>
            <span>Source Category</span>
            <select id="ds-form-source-category">${ENUMS.sourceCategory
              .map((it) => `<option value="${it}" ${it === f.source_category ? 'selected' : ''}>${it}</option>`)
              .join('')}</select>
          </label>
          <label>
            <span>Crawl Mode</span>
            <select id="ds-form-crawl-mode">${ENUMS.crawlMode
              .map((it) => `<option value="${it}" ${it === f.crawl_mode ? 'selected' : ''}>${it}</option>`)
              .join('')}</select>
          </label>
        </div>
        <label><span>Crawl Interval Minutes</span><input id="ds-form-crawl-interval" type="number" min="1" value="${escapeHtml(
          f.crawl_interval_minutes
        )}"></label>
      `
        : '';

    return `
      <div class="modal-backdrop" data-action="ds-modal-close">
        <div class="modal" role="dialog" aria-modal="true">
          <div class="modal-head">
            <h3>${title}</h3>
            <button class="ghost" data-action="ds-modal-close">Close</button>
          </div>
          <div class="modal-body">
            <label><span>Name *</span><input id="ds-form-name" type="text" value="${escapeHtml(f.name)}"></label>
            <label><span>Description</span><textarea id="ds-form-description" rows="2">${escapeHtml(
              f.description
            )}</textarea></label>
            ${createOnly}
            <label><span>Config JSON</span><textarea id="ds-form-config" rows="4">${escapeHtml(f.config)}</textarea></label>
            <label><span>Account Ref JSON</span><textarea id="ds-form-account-ref" rows="3">${escapeHtml(
              f.account_ref
            )}</textarea></label>
          </div>
          <div class="modal-foot">
            <button class="secondary" data-action="ds-modal-close">Cancel</button>
            <button class="primary" data-action="ds-save">Save</button>
          </div>
        </div>
      </div>
    `;
  }

  function renderTargetModal() {
    if (!pageState.target.form.open) return '';
    const f = pageState.target.form;
    const title = f.mode === 'create' ? 'Create Target' : 'Edit Target';
    const typeField =
      f.mode === 'create'
        ? `<label><span>Target Type</span><select id="tg-form-type">${ENUMS.targetTypePath
            .map((it) => `<option value="${it}" ${it === f.type ? 'selected' : ''}>${it}</option>`)
            .join('')}</select></label>`
        : `<label><span>Target Type</span><input value="${escapeHtml(f.type)}" disabled></label>`;

    return `
      <div class="modal-backdrop" data-action="tg-modal-close">
        <div class="modal" role="dialog" aria-modal="true">
          <div class="modal-head">
            <h3>${title}</h3>
            <button class="ghost" data-action="tg-modal-close">Close</button>
          </div>
          <div class="modal-body">
            ${typeField}
            <label><span>Label</span><input id="tg-form-label" type="text" value="${escapeHtml(f.label)}"></label>
            <div class="grid three">
              <label><span>Priority</span><input id="tg-form-priority" type="number" value="${escapeHtml(f.priority)}"></label>
              <label><span>Interval *</span><input id="tg-form-interval" type="number" min="1" value="${escapeHtml(
                f.interval
              )}"></label>
              <label class="check-field"><input id="tg-form-active" type="checkbox" ${
      f.is_active ? 'checked' : ''
    }><span>Active</span></label>
            </div>
            <label><span>Values (one per line) *</span><textarea id="tg-form-values" rows="6">${escapeHtml(
              f.values
            )}</textarea></label>
            <label><span>Platform Meta JSON</span><textarea id="tg-form-meta" rows="3">${escapeHtml(
              f.platform_meta
            )}</textarea></label>
          </div>
          <div class="modal-foot">
            <button class="secondary" data-action="tg-modal-close">Cancel</button>
            <button class="primary" data-action="tg-save">Save</button>
          </div>
        </div>
      </div>
    `;
  }

  function renderWizardTargetDrafts() {
    return pageState.wizard.targets
      .map((target, index) => {
        return `
          <div class="draft-card" data-draft-id="${target.id}">
            <div class="draft-head">
              <h4>Target Draft #${index + 1}</h4>
              <button class="ghost danger" data-action="wizard-remove-target" data-id="${target.id}">Remove</button>
            </div>
            <div class="grid three">
              <label>
                <span>Type</span>
                <select data-field="type" data-id="${target.id}">
                  ${ENUMS.targetTypePath
                    .map((it) => `<option value="${it}" ${it === target.type ? 'selected' : ''}>${it}</option>`)
                    .join('')}
                </select>
              </label>
              <label>
                <span>Priority</span>
                <input data-field="priority" data-id="${target.id}" type="number" value="${escapeHtml(target.priority)}">
              </label>
              <label>
                <span>Interval</span>
                <input data-field="interval" data-id="${target.id}" type="number" min="1" value="${escapeHtml(
          target.interval
        )}">
              </label>
            </div>
            <label><span>Label</span><input data-field="label" data-id="${target.id}" type="text" value="${escapeHtml(
          target.label
        )}"></label>
            <label><span>Values (one per line) *</span><textarea data-field="values" data-id="${target.id}" rows="4">${escapeHtml(
          target.values
        )}</textarea></label>
            <label><span>Platform Meta JSON</span><textarea data-field="platform_meta" data-id="${target.id}" rows="3">${escapeHtml(
          target.platform_meta
        )}</textarea></label>
            <label class="check-field"><input data-field="is_active" data-id="${target.id}" type="checkbox" ${
          target.is_active ? 'checked' : ''
        }><span>Active</span></label>
          </div>
        `;
      })
      .join('');
  }

  function renderWizardStepContent() {
    const w = pageState.wizard;

    if (w.step === 1) {
      return `
        <div class="wizard-step-grid">
          <label><span>Project Name *</span><input id="wiz-project-name" type="text" value="${escapeHtml(
            w.project.name
          )}"></label>
          <label><span>Brand</span><input id="wiz-project-brand" type="text" value="${escapeHtml(
            w.project.brand
          )}"></label>
          <label><span>Entity Type *</span><select id="wiz-project-entity-type">${ENUMS.entityType
            .map((it) => `<option value="${it}" ${it === w.project.entity_type ? 'selected' : ''}>${it}</option>`)
            .join('')}</select></label>
          <label><span>Entity Name *</span><input id="wiz-project-entity-name" type="text" value="${escapeHtml(
            w.project.entity_name
          )}"></label>
          <label class="full"><span>Description</span><textarea id="wiz-project-description" rows="3">${escapeHtml(
            w.project.description
          )}</textarea></label>
        </div>
      `;
    }

    if (w.step === 2) {
      return `
        <div class="wizard-step-grid">
          <label><span>Datasource Name *</span><input id="wiz-ds-name" type="text" value="${escapeHtml(
            w.datasource.name
          )}"></label>
          <label><span>Source Type *</span><select id="wiz-ds-source-type">${ENUMS.sourceType
            .map((it) => `<option value="${it}" ${it === w.datasource.source_type ? 'selected' : ''}>${it}</option>`)
            .join('')}</select></label>
          <label><span>Source Category *</span><select id="wiz-ds-source-category">${ENUMS.sourceCategory
            .map((it) => `<option value="${it}" ${it === w.datasource.source_category ? 'selected' : ''}>${it}</option>`)
            .join('')}</select></label>
          <label><span>Crawl Mode</span><select id="wiz-ds-crawl-mode">${ENUMS.crawlMode
            .map((it) => `<option value="${it}" ${it === w.datasource.crawl_mode ? 'selected' : ''}>${it}</option>`)
            .join('')}</select></label>
          <label><span>Crawl Interval</span><input id="wiz-ds-crawl-interval" type="number" min="1" value="${escapeHtml(
            w.datasource.crawl_interval_minutes
          )}"></label>
          <label class="full"><span>Description</span><textarea id="wiz-ds-description" rows="2">${escapeHtml(
            w.datasource.description
          )}</textarea></label>
          <label class="full"><span>Config JSON</span><textarea id="wiz-ds-config" rows="4">${escapeHtml(
            w.datasource.config
          )}</textarea></label>
          <label class="full"><span>Account Ref JSON</span><textarea id="wiz-ds-account-ref" rows="3">${escapeHtml(
            w.datasource.account_ref
          )}</textarea></label>
        </div>
      `;
    }

    if (w.step === 3) {
      return `
        <div class="wizard-target-head">
          <p>Configure one or more crawl targets for this datasource.</p>
          <button class="secondary" data-action="wizard-add-target">Add Target Draft</button>
        </div>
        <div class="draft-list">
          ${renderWizardTargetDrafts()}
        </div>
      `;
    }

    if (w.step === 4) {
      const review = {
        campaign_id: pageState.selectedCampaignId,
        project: w.project,
        datasource: w.datasource,
        targets: w.targets.map((item) => ({
          type: item.type,
          label: item.label,
          values: parseValuesLines(item.values),
          priority: Number(item.priority || 1),
          crawl_interval_minutes: Number(item.interval || 11),
          is_active: item.is_active,
          platform_meta: item.platform_meta,
        })),
      };

      return `<pre class="review-block">${escapeHtml(pretty(review))}</pre>`;
    }

    const p = w.pipeline;

    return `
      <div class="pipeline-block">
        <h4>Submit Pipeline Result</h4>
        <p>Run sequence: create project -> create datasource -> create targets.</p>
        <div class="pipeline-meta">
          <div><span>Project ID:</span> <code>${escapeHtml(p.projectId || '-')}</code></div>
          <div><span>Datasource ID:</span> <code>${escapeHtml(p.datasourceId || '-')}</code></div>
          <div><span>Target IDs:</span> <code>${escapeHtml(p.targetIds.join(', ') || '-')}</code></div>
          <div><span>Failed Step:</span> <code>${escapeHtml(p.failedStep || '-')}</code></div>
        </div>

        ${w.success ? `<div class="success-block">${escapeHtml(w.success)}</div>` : ''}
        ${w.error ? `<div class="error-block">${escapeHtml(w.error)}</div>` : ''}
        ${p.error ? `<pre class="review-block">${escapeHtml(p.error)}</pre>` : ''}

        <div class="pipeline-actions">
          <button class="primary" data-action="wizard-run-submit" ${w.submitting ? 'disabled' : ''}>${
      w.submitting ? 'Submitting...' : 'Run Pipeline Create'
    }</button>
          <button class="secondary" data-action="wizard-close">Close Wizard</button>
        </div>

        <div class="cleanup-block">
          <h5>Manual Cleanup</h5>
          <p>No automatic rollback is executed. Use actions below if needed.</p>
          <div class="cleanup-actions">
            ${p.datasourceId ? '<button class="danger" data-action="cleanup-datasource">Archive Datasource</button>' : ''}
            ${p.projectId ? '<button class="danger" data-action="cleanup-project">Archive Project</button>' : ''}
          </div>
          <div class="cleanup-targets">
            ${p.targetIds
              .map(
                (id) =>
                  `<button class="danger ghost" data-action="cleanup-target" data-id="${id}">Delete Target ${escapeHtml(
                    id.slice(0, 8)
                  )}</button>`
              )
              .join('')}
          </div>
        </div>
      </div>
    `;
  }

  function renderWizard() {
    if (!pageState.wizard.open) return '';

    const w = pageState.wizard;

    return `
      <div class="modal-backdrop" data-action="wizard-close">
        <div class="modal modal-lg" role="dialog" aria-modal="true">
          <div class="modal-head">
            <h3>Project Setup Wizard</h3>
            <span class="step-pill">Step ${w.step} / 5</span>
          </div>
          <div class="modal-body wizard-body">
            <div class="wizard-progress">
              <div class="line"><span style="width:${((w.step - 1) / 4) * 100}%"></span></div>
              <div class="labels">
                <span>Project</span>
                <span>Datasource</span>
                <span>Target</span>
                <span>Review</span>
                <span>Submit</span>
              </div>
            </div>
            ${renderWizardStepContent()}
          </div>
          <div class="modal-foot">
            <button class="secondary" data-action="wizard-close">Cancel</button>
            ${w.step > 1 ? '<button class="secondary" data-action="wizard-prev">Previous</button>' : ''}
            ${w.step < 5 ? '<button class="primary" data-action="wizard-next">Next</button>' : ''}
            ${w.step === 5 ? '<button class="primary" data-action="wizard-run-submit">Run Pipeline Create</button>' : ''}
          </div>
        </div>
      </div>
    `;
  }

  function render() {
    const selectedProject = getSelectedProject();
    const selectedDatasource = getSelectedDatasource();
    const totalPages = Math.max(1, Math.ceil(pageState.total / pageState.limit));

    container.innerHTML = `
      <section class="page-head compact">
        <div>
          <h2>Project Management</h2>
          <p>Create projects with wizard, then manage datasource and crawl targets.</p>
        </div>
        <div class="head-actions">
          ${renderCampaignSelector()}
          <button class="primary" id="open-wizard-btn">Create Project (Wizard)</button>
        </div>
      </section>

      <section class="card panel-grid">
        <div class="toolbar">
          <input id="project-search" type="text" placeholder="Search project name" value="${escapeHtml(
            pageState.projectQuery
          )}">
          <button class="secondary" id="project-search-btn">Search</button>
          <button class="secondary" id="project-refresh-btn">Refresh</button>
        </div>

        ${pageState.projectLoading ? renderLoadingBlock('Loading projects...') : ''}
        ${pageState.projectError ? renderErrorBlock(pageState.projectError) : ''}

        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Entity</th>
                <th>Status</th>
                <th>Updated</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              ${!pageState.projectLoading ? renderProjectRows() : ''}
            </tbody>
          </table>
        </div>

        <div class="pager">
          <button class="secondary" id="project-prev" ${pageState.page <= 1 ? 'disabled' : ''}>Prev</button>
          <span>Page ${pageState.page} / ${totalPages}</span>
          <button class="secondary" id="project-next" ${pageState.page >= totalPages ? 'disabled' : ''}>Next</button>
        </div>
      </section>

      <section class="card detail-card">
        <div class="detail-head">
          <h3>Project Detail</h3>
          <span class="mono">${escapeHtml(pageState.selectedProjectId || '-')}</span>
        </div>
        <pre>${selectedProject ? escapeHtml(pretty(selectedProject)) : 'Select a project row first.'}</pre>
      </section>

      <section class="card panel-grid">
        ${renderConfigTabs()}
        ${pageState.activeTab === 'datasources' ? renderDatasourcePanel(selectedDatasource) : renderTargetPanel()}
      </section>

      ${renderProjectEditModal()}
      ${renderDatasourceModal()}
      ${renderTargetModal()}
      ${renderWizard()}
    `;

    bindEvents();
  }

  function bindEvents() {
    const campaignSelect = container.querySelector('#project-campaign-select');
    if (campaignSelect) {
      campaignSelect.addEventListener('change', () => {
        pageState.selectedCampaignId = campaignSelect.value;
        setState({ selectedCampaignId: pageState.selectedCampaignId });
        pageState.page = 1;
        pageState.selectedProjectId = null;
        pageState.datasource.selectedId = null;
        loadProjects();
      });
    }

    const wizardBtn = container.querySelector('#open-wizard-btn');
    if (wizardBtn) wizardBtn.addEventListener('click', openWizard);

    const searchBtn = container.querySelector('#project-search-btn');
    if (searchBtn) {
      searchBtn.addEventListener('click', () => {
        const input = container.querySelector('#project-search');
        pageState.projectQuery = input.value.trim();
        pageState.page = 1;
        loadProjects();
      });
    }

    const refreshBtn = container.querySelector('#project-refresh-btn');
    if (refreshBtn) refreshBtn.addEventListener('click', loadProjects);

    const prevBtn = container.querySelector('#project-prev');
    if (prevBtn) {
      prevBtn.addEventListener('click', () => {
        if (pageState.page > 1) {
          pageState.page -= 1;
          loadProjects();
        }
      });
    }

    const nextBtn = container.querySelector('#project-next');
    if (nextBtn) {
      nextBtn.addEventListener('click', () => {
        pageState.page += 1;
        loadProjects();
      });
    }

    container.querySelectorAll('[data-action="project-select"]').forEach((btn) => {
      btn.addEventListener('click', async () => {
        pageState.selectedProjectId = btn.getAttribute('data-id');
        setState({ selectedProjectId: pageState.selectedProjectId });
        await loadDatasources();
        render();
      });
    });

    container.querySelectorAll('[data-action="project-edit"]').forEach((btn) => {
      btn.addEventListener('click', () => openProjectEditForm(btn.getAttribute('data-id')));
    });

    container.querySelectorAll('[data-action="project-archive"]').forEach((btn) => {
      btn.addEventListener('click', () => archiveProject(btn.getAttribute('data-id')));
    });

    container.querySelectorAll('[data-action="project-modal-close"]').forEach((btn) => {
      btn.addEventListener('click', (event) => {
        if (btn.classList.contains('modal-backdrop') && event.target !== btn) {
          return;
        }
        closeProjectEditForm();
      });
    });

    const projectSaveBtn = container.querySelector('[data-action="project-save"]');
    if (projectSaveBtn) {
      projectSaveBtn.addEventListener('click', () => {
        pageState.projectForm.name = container.querySelector('#project-form-name').value;
        pageState.projectForm.description = container.querySelector('#project-form-description').value;
        pageState.projectForm.brand = container.querySelector('#project-form-brand').value;
        pageState.projectForm.entity_type = container.querySelector('#project-form-entity-type').value;
        pageState.projectForm.entity_name = container.querySelector('#project-form-entity-name').value;
        pageState.projectForm.status = container.querySelector('#project-form-status').value;
        saveProjectEdit();
      });
    }

    const dsCreateBtn = container.querySelector('#ds-create-btn');
    if (dsCreateBtn) dsCreateBtn.addEventListener('click', () => openDatasourceForm('create'));
    const dsRefreshBtn = container.querySelector('#ds-refresh-btn');
    if (dsRefreshBtn) dsRefreshBtn.addEventListener('click', loadDatasources);

    container.querySelectorAll('[data-action="datasource-select"]').forEach((btn) => {
      btn.addEventListener('click', async () => {
        pageState.datasource.selectedId = btn.getAttribute('data-id');
        setState({ selectedDatasourceId: pageState.datasource.selectedId });
        await loadTargets();
        render();
      });
    });

    container.querySelectorAll('[data-action="switch-tab"]').forEach((btn) => {
      btn.addEventListener('click', () => {
        pageState.activeTab = btn.getAttribute('data-tab');
        render();
      });
    });

    container.querySelectorAll('[data-action="datasource-edit"]').forEach((btn) => {
      btn.addEventListener('click', () => openDatasourceForm('edit', btn.getAttribute('data-id')));
    });

    container.querySelectorAll('[data-action="datasource-archive"]').forEach((btn) => {
      btn.addEventListener('click', () => archiveDatasource(btn.getAttribute('data-id')));
    });

    container.querySelectorAll('[data-action="ds-modal-close"]').forEach((btn) => {
      btn.addEventListener('click', (event) => {
        if (btn.classList.contains('modal-backdrop') && event.target !== btn) {
          return;
        }
        closeDatasourceForm();
      });
    });

    const dsSaveBtn = container.querySelector('[data-action="ds-save"]');
    if (dsSaveBtn) {
      dsSaveBtn.addEventListener('click', () => {
        const f = pageState.datasource.form;
        f.name = container.querySelector('#ds-form-name').value;
        f.description = container.querySelector('#ds-form-description').value;
        const sourceType = container.querySelector('#ds-form-source-type');
        const sourceCategory = container.querySelector('#ds-form-source-category');
        const crawlMode = container.querySelector('#ds-form-crawl-mode');
        const crawlInterval = container.querySelector('#ds-form-crawl-interval');
        f.source_type = sourceType ? sourceType.value : f.source_type;
        f.source_category = sourceCategory ? sourceCategory.value : f.source_category;
        f.crawl_mode = crawlMode ? crawlMode.value : f.crawl_mode;
        f.crawl_interval_minutes = crawlInterval ? crawlInterval.value : f.crawl_interval_minutes;
        f.config = container.querySelector('#ds-form-config').value;
        f.account_ref = container.querySelector('#ds-form-account-ref').value;
        saveDatasourceForm();
      });
    }

    const tgCreateBtn = container.querySelector('#target-create-btn');
    if (tgCreateBtn) tgCreateBtn.addEventListener('click', () => openTargetForm('create'));
    const tgRefreshBtn = container.querySelector('#target-refresh-btn');
    if (tgRefreshBtn) tgRefreshBtn.addEventListener('click', loadTargets);

    container.querySelectorAll('[data-action="target-edit"]').forEach((btn) => {
      btn.addEventListener('click', () => openTargetForm('edit', btn.getAttribute('data-id')));
    });

    container.querySelectorAll('[data-action="target-delete"]').forEach((btn) => {
      btn.addEventListener('click', () => deleteTarget(btn.getAttribute('data-id')));
    });

    container.querySelectorAll('[data-action="tg-modal-close"]').forEach((btn) => {
      btn.addEventListener('click', (event) => {
        if (btn.classList.contains('modal-backdrop') && event.target !== btn) {
          return;
        }
        closeTargetForm();
      });
    });

    const tgSaveBtn = container.querySelector('[data-action="tg-save"]');
    if (tgSaveBtn) {
      tgSaveBtn.addEventListener('click', () => {
        const f = pageState.target.form;
        const typeInput = container.querySelector('#tg-form-type');
        f.type = typeInput ? typeInput.value : f.type;
        f.label = container.querySelector('#tg-form-label').value;
        f.values = container.querySelector('#tg-form-values').value;
        f.priority = container.querySelector('#tg-form-priority').value;
        f.interval = container.querySelector('#tg-form-interval').value;
        f.platform_meta = container.querySelector('#tg-form-meta').value;
        f.is_active = container.querySelector('#tg-form-active').checked;
        saveTargetForm();
      });
    }

    container.querySelectorAll('[data-action="wizard-close"]').forEach((btn) => {
      btn.addEventListener('click', (event) => {
        if (btn.classList.contains('modal-backdrop') && event.target !== btn) {
          return;
        }
        closeWizard();
      });
    });

    const wizardNextBtn = container.querySelector('[data-action="wizard-next"]');
    if (wizardNextBtn) {
      wizardNextBtn.addEventListener('click', () => {
        pullWizardStepInputs();
        wizardNext();
      });
    }

    const wizardPrevBtn = container.querySelector('[data-action="wizard-prev"]');
    if (wizardPrevBtn) {
      wizardPrevBtn.addEventListener('click', wizardPrev);
    }

    container.querySelectorAll('[data-action="wizard-run-submit"]').forEach((wizardSubmitBtn) => {
      wizardSubmitBtn.addEventListener('click', () => {
        pullWizardStepInputs();
        runPipelineCreate();
      });
    });

    const wizardAddTargetBtn = container.querySelector('[data-action="wizard-add-target"]');
    if (wizardAddTargetBtn) {
      wizardAddTargetBtn.addEventListener('click', () => {
        pageState.wizard.targets.push(defaultTargetDraft());
        render();
      });
    }

    container.querySelectorAll('[data-action="wizard-remove-target"]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const id = btn.getAttribute('data-id');
        pageState.wizard.targets = pageState.wizard.targets.filter((item) => item.id !== id);
        if (!pageState.wizard.targets.length) {
          pageState.wizard.targets.push(defaultTargetDraft());
        }
        render();
      });
    });

    container.querySelectorAll('.draft-card [data-field]').forEach((el) => {
      const eventName = el.type === 'checkbox' || el.tagName === 'SELECT' ? 'change' : 'input';
      el.addEventListener(eventName, () => {
        const id = el.getAttribute('data-id');
        const field = el.getAttribute('data-field');
        const item = pageState.wizard.targets.find((target) => target.id === id);
        if (!item || !field) return;
        if (field === 'is_active') {
          item[field] = el.checked;
        } else {
          item[field] = el.value;
        }
      });
    });

    const cleanupDsBtn = container.querySelector('[data-action="cleanup-datasource"]');
    if (cleanupDsBtn) {
      cleanupDsBtn.addEventListener('click', () =>
        cleanupCreatedEntity('datasource', pageState.wizard.pipeline.datasourceId)
      );
    }

    const cleanupProjectBtn = container.querySelector('[data-action="cleanup-project"]');
    if (cleanupProjectBtn) {
      cleanupProjectBtn.addEventListener('click', () =>
        cleanupCreatedEntity('project', pageState.wizard.pipeline.projectId)
      );
    }

    container.querySelectorAll('[data-action="cleanup-target"]').forEach((btn) => {
      btn.addEventListener('click', () => cleanupTarget(btn.getAttribute('data-id')));
    });
  }

  function pullWizardStepInputs() {
    const w = pageState.wizard;
    if (!w.open) return;

    if (w.step === 1) {
      const q = (selector) => container.querySelector(selector);
      w.project.name = q('#wiz-project-name') ? q('#wiz-project-name').value : w.project.name;
      w.project.description = q('#wiz-project-description')
        ? q('#wiz-project-description').value
        : w.project.description;
      w.project.brand = q('#wiz-project-brand') ? q('#wiz-project-brand').value : w.project.brand;
      w.project.entity_type = q('#wiz-project-entity-type')
        ? q('#wiz-project-entity-type').value
        : w.project.entity_type;
      w.project.entity_name = q('#wiz-project-entity-name')
        ? q('#wiz-project-entity-name').value
        : w.project.entity_name;
    }

    if (w.step === 2) {
      const q = (selector) => container.querySelector(selector);
      w.datasource.name = q('#wiz-ds-name') ? q('#wiz-ds-name').value : w.datasource.name;
      w.datasource.description = q('#wiz-ds-description')
        ? q('#wiz-ds-description').value
        : w.datasource.description;
      w.datasource.source_type = q('#wiz-ds-source-type')
        ? q('#wiz-ds-source-type').value
        : w.datasource.source_type;
      w.datasource.source_category = q('#wiz-ds-source-category')
        ? q('#wiz-ds-source-category').value
        : w.datasource.source_category;
      w.datasource.crawl_mode = q('#wiz-ds-crawl-mode')
        ? q('#wiz-ds-crawl-mode').value
        : w.datasource.crawl_mode;
      w.datasource.crawl_interval_minutes = q('#wiz-ds-crawl-interval')
        ? q('#wiz-ds-crawl-interval').value
        : w.datasource.crawl_interval_minutes;
      w.datasource.config = q('#wiz-ds-config') ? q('#wiz-ds-config').value : w.datasource.config;
      w.datasource.account_ref = q('#wiz-ds-account-ref')
        ? q('#wiz-ds-account-ref').value
        : w.datasource.account_ref;
    }
  }

  (async () => {
    await loadCampaignOptions();
    await loadProjects();
  })();

  return () => {
    container.innerHTML = '';
  };
}
