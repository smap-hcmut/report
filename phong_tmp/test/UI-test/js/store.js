const state = {
  auth: {
    status: 'checking',
    user: null,
    error: '',
  },
  campaigns: [],
  selectedCampaignId: null,
  projects: [],
  selectedProjectId: null,
  datasources: [],
  selectedDatasourceId: null,
  targets: [],
};

const listeners = new Set();

export function getState() {
  return state;
}

export function setState(patch) {
  Object.assign(state, patch);
  listeners.forEach((cb) => cb(state));
}

export function subscribe(cb) {
  listeners.add(cb);
  return () => listeners.delete(cb);
}

export function getSelectedCampaign() {
  return state.campaigns.find((item) => item.id === state.selectedCampaignId) || null;
}

export function getSelectedProject() {
  return state.projects.find((item) => item.id === state.selectedProjectId) || null;
}

export function getSelectedDatasource() {
  return state.datasources.find((item) => item.id === state.selectedDatasourceId) || null;
}
