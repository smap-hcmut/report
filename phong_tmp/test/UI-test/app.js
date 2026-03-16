(function () {
  "use strict";

  const CFG = {
    identity: "https://smap-api.tantai.dev/identity/api/v1",
    project: "https://smap-api.tantai.dev/project/api/v1",
    ingest: "https://smap-api.tantai.dev/ingest/api/v1",
    knowledge: "https://smap-api.tantai.dev/knowledge/api/v1/knowledge",
    scraper: "https://smap-api.tantai.dev/scraper/api/v1",
    notificationWs: "wss://smap-api.tantai.dev/notification/api/v1/ws",
  };

  const CRISIS_SAMPLE = {
    keywords_trigger: {
      enabled: true,
      logic: "OR",
      groups: [
        {
          name: "Sample keywords",
          keywords: ["brand crisis", "service outage"],
          weight: 10,
        },
      ],
    },
    volume_trigger: {
      enabled: true,
      metric: "MENTIONS",
      rules: [
        {
          level: "CRITICAL",
          threshold_percent_growth: 180,
          comparison_window_hours: 1,
          baseline: "PREVIOUS_PERIOD",
        },
      ],
    },
  };

  const STATE = {
    user: null,
    campaigns: [],
    selectedCampaignId: null,
    selectedCampaign: null,
    projects: [],
    selectedProjectId: null,
    selectedProject: null,
    datasources: [],
    selectedDatasourceId: null,
    selectedDatasource: null,
    targets: [],
    selectedTargetId: null,
    selectedTarget: null,
    // Knowledge
    conversationId: null,
    chatMessages: [],
    // Report
    currentReportId: null,
    reportPollTimer: null,
    // Scraper
    lastScraperTaskId: null,
    // WebSocket
    ws: null,
    wsReconnectAttempts: 0,
    wsReconnectTimer: null,
  };

  const el = {};

  function cacheElements() {
    const ids = [
      "auth-pill",
      "login-btn",
      "logout-btn",
      "refresh-auth-btn",
      "user-info",
      "runtime-config",
      "workspace",
      "workspace-lock",
      "context-bar",
      "campaign-form",
      "campaign-edit-id",
      "campaign-name",
      "campaign-status",
      "campaign-description",
      "campaign-start",
      "campaign-end",
      "reset-campaign-btn",
      "refresh-campaigns-btn",
      "campaign-list",
      "campaign-detail",
      "project-form",
      "project-edit-id",
      "project-name",
      "project-brand",
      "project-entity-type",
      "project-entity-name",
      "project-description",
      "project-status",
      "reset-project-btn",
      "refresh-projects-btn",
      "project-list",
      "project-detail",
      "crisis-form",
      "crisis-json",
      "load-crisis-sample-btn",
      "refresh-crisis-btn",
      "delete-crisis-btn",
      "crisis-detail",
      "datasource-form",
      "datasource-edit-id",
      "datasource-name",
      "datasource-source-type",
      "datasource-source-category",
      "datasource-crawl-mode",
      "datasource-crawl-interval",
      "datasource-description",
      "datasource-config",
      "datasource-account-ref",
      "reset-datasource-btn",
      "refresh-datasources-btn",
      "datasource-list",
      "datasource-detail",
      "target-form",
      "target-edit-id",
      "target-type",
      "target-priority",
      "target-crawl-interval",
      "target-label",
      "target-values",
      "target-platform-meta",
      "target-is-active",
      "reset-target-btn",
      "refresh-targets-btn",
      "target-list",
      "target-detail",
      "debug-output",
      "toast-stack",
      // Knowledge Chat
      "chat-form",
      "chat-input",
      "chat-msgs",
      "chat-suggestions",
      "new-conversation-btn",
      "load-suggestions-btn",
      // Knowledge Search
      "search-form",
      "search-query",
      "search-sentiment",
      "search-platform",
      "search-date-from",
      "search-date-to",
      "search-result",
      // Knowledge Reports
      "report-form",
      "report-type",
      "report-status-row",
      "report-id-display",
      "report-status-display",
      "report-detail",
      "report-download-row",
      "report-download-link",
      "refresh-report-btn",
      // Scraper
      "scraper-form",
      "scraper-platform",
      "scraper-action",
      "scraper-params",
      "scraper-task-id-row",
      "scraper-task-id-display",
      "scraper-result",
      "refresh-scraper-tasks-btn",
      "fetch-scraper-result-btn",
      // WebSocket / Notifications
      "ws-pill",
      "ws-connect-btn",
      "ws-disconnect-btn",
      "notification-feed",
    ];

    ids.forEach(function (id) {
      el[id] = document.getElementById(id);
    });
  }

  function init() {
    cacheElements();
    bindEvents();
    renderRuntimeConfig();
    setAuthPill("Checking session", "idle");
    setWorkspaceState(false);
    resetCampaignForm();
    resetProjectForm();
    resetDatasourceForm();
    resetTargetForm();
    loadCrisisSample();
    refreshAuth();
  }

  function bindEvents() {
    el["login-btn"].addEventListener("click", login);
    bindAsync(el["logout-btn"], "click", logout);
    bindAsync(el["refresh-auth-btn"], "click", refreshAuth);

    bindAsync(el["campaign-form"], "submit", saveCampaign);
    el["reset-campaign-btn"].addEventListener("click", resetCampaignForm);
    bindAsync(el["refresh-campaigns-btn"], "click", loadCampaigns);

    bindAsync(el["project-form"], "submit", saveProject);
    el["reset-project-btn"].addEventListener("click", resetProjectForm);
    bindAsync(el["refresh-projects-btn"], "click", loadProjects);

    bindAsync(el["crisis-form"], "submit", saveCrisisConfig);
    el["load-crisis-sample-btn"].addEventListener("click", loadCrisisSample);
    bindAsync(el["refresh-crisis-btn"], "click", loadCrisisConfig);
    bindAsync(el["delete-crisis-btn"], "click", deleteCrisisConfig);

    bindAsync(el["datasource-form"], "submit", saveDatasource);
    el["reset-datasource-btn"].addEventListener("click", resetDatasourceForm);
    bindAsync(el["refresh-datasources-btn"], "click", loadDatasources);

    bindAsync(el["target-form"], "submit", saveTarget);
    el["reset-target-btn"].addEventListener("click", resetTargetForm);
    bindAsync(el["refresh-targets-btn"], "click", loadTargets);

    // Knowledge Chat
    bindAsync(el["chat-form"], "submit", sendChat);
    el["new-conversation-btn"].addEventListener("click", newConversation);
    bindAsync(el["load-suggestions-btn"], "click", loadSuggestions);

    // Knowledge Search
    bindAsync(el["search-form"], "submit", doSearch);

    // Knowledge Reports
    bindAsync(el["report-form"], "submit", generateReport);
    bindAsync(el["refresh-report-btn"], "click", refreshReportStatus);

    // Scraper
    bindAsync(el["scraper-form"], "submit", submitScraperTask);
    bindAsync(el["refresh-scraper-tasks-btn"], "click", listScraperTasks);
    bindAsync(el["fetch-scraper-result-btn"], "click", fetchScraperResult);

    // WebSocket
    el["ws-connect-btn"].addEventListener("click", wsConnect);
    el["ws-disconnect-btn"].addEventListener("click", wsDisconnect);
  }

  function bindAsync(node, eventName, handler) {
    node.addEventListener(eventName, function (event) {
      Promise.resolve(handler(event)).catch(handleUiError);
    });
  }

  function renderRuntimeConfig() {
    const redirectTarget = buildRedirectTarget();
    el["runtime-config"].textContent = JSON.stringify(
      {
        identity: CFG.identity,
        project: CFG.project,
        ingest: CFG.ingest,
        knowledge: CFG.knowledge,
        scraper: CFG.scraper,
        notification_ws: CFG.notificationWs,
        ui_origin: window.location.origin,
        redirect_target: redirectTarget,
        swagger_docs: {
          identity: "https://smap-api.tantai.dev/identity/swagger/index.html",
          project: "https://smap-api.tantai.dev/project/swagger/index.html",
          ingest: "https://smap-api.tantai.dev/ingest/swagger/index.html",
          knowledge: "https://smap-api.tantai.dev/knowledge/swagger/index.html",
          scraper: "https://smap-api.tantai.dev/scraper/docs",
        },
      },
      null,
      2
    );
  }

  function buildRedirectTarget() {
    return window.location.origin + window.location.pathname;
  }

  function setAuthPill(message, kind) {
    el["auth-pill"].textContent = message;
    el["auth-pill"].className = "status-pill status-" + kind;
  }

  function setWorkspaceState(enabled) {
    el["workspace"].classList.toggle("hidden", !enabled);
    el["workspace-lock"].classList.toggle("hidden", enabled);
    el["logout-btn"].classList.toggle("hidden", !enabled);
    el["login-btn"].classList.toggle("hidden", enabled);
  }

  function showToast(message, kind) {
    const item = document.createElement("div");
    item.className = "toast " + kind;
    item.textContent = message;
    el["toast-stack"].appendChild(item);
    setTimeout(function () {
      item.remove();
    }, 3200);
  }

  function escapeHtml(value) {
    return String(value == null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function pretty(value) {
    return JSON.stringify(value, null, 2);
  }

  function showDetail(id, value) {
    el[id].textContent = typeof value === "string" ? value : pretty(value);
  }

  function showDebug(entry) {
    el["debug-output"].textContent = pretty(entry);
  }

  function formatDateTimeLocal(value) {
    if (!value) {
      return "";
    }
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
      return "";
    }
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");
    const hour = String(date.getHours()).padStart(2, "0");
    const minute = String(date.getMinutes()).padStart(2, "0");
    return `${year}-${month}-${day}T${hour}:${minute}`;
  }

  function parseOptionalJson(text, fieldName) {
    const raw = text.trim();
    if (!raw) {
      return undefined;
    }
    try {
      return JSON.parse(raw);
    } catch (error) {
      throw new Error(fieldName + " JSON is invalid");
    }
  }

  function toLines(values) {
    return (values || []).join("\n");
  }

  function getEffectiveStatus(httpStatus, body) {
    if (
      httpStatus === 200 &&
      body &&
      typeof body === "object" &&
      typeof body.error_code === "number" &&
      body.error_code !== 0
    ) {
      return body.error_code;
    }
    return httpStatus;
  }

  function extractMessage(body, effectiveStatus) {
    if (body && typeof body === "object" && typeof body.message === "string") {
      return body.message;
    }
    return "Request failed with status " + effectiveStatus;
  }

  async function request(base, path, options) {
    const opts = options || {};
    const method = opts.method || "GET";
    const allowStatuses = opts.allowStatuses || [200];
    const url = base + path;
    const headers = { Accept: "application/json" };
    let body;
    if (opts.body !== undefined) {
      headers["Content-Type"] = "application/json";
      body = JSON.stringify(opts.body);
    }
    const response = await fetch(url, {
      method: method,
      headers: headers,
      body: body,
      credentials: "include",
    });
    const raw = await response.text();
    let parsed = raw;
    try {
      parsed = raw ? JSON.parse(raw) : null;
    } catch (error) {
      parsed = raw;
    }
    const effectiveStatus = getEffectiveStatus(response.status, parsed);
    showDebug({
      method: method,
      url: url,
      request_body: opts.body === undefined ? null : opts.body,
      http_status: response.status,
      effective_status: effectiveStatus,
      response_body: parsed,
    });
    if (allowStatuses.indexOf(effectiveStatus) === -1) {
      const message = extractMessage(parsed, effectiveStatus);
      const err = new Error(message);
      err.httpStatus = response.status;
      err.status = effectiveStatus;
      err.responseBody = parsed;
      throw err;
    }
    return {
      httpStatus: response.status,
      status: effectiveStatus,
      body: parsed,
      data: parsed && typeof parsed === "object" ? parsed.data || null : null,
    };
  }

  async function refreshAuth() {
    try {
      const result = await request(CFG.identity, "/authentication/me", {
        allowStatuses: [200, 401],
      });
      if (result.status === 200) {
        STATE.user = result.data;
        setAuthPill("Authenticated", "ok");
        setWorkspaceState(true);
        showDetail("user-info", STATE.user);
        updateContextBar();
        loadCampaigns().catch(handleUiError);
      } else {
        clearWorkspaceState();
        setAuthPill("Not authenticated", "idle");
        setWorkspaceState(false);
        showDetail("user-info", "Not authenticated");
      }
    } catch (error) {
      clearWorkspaceState();
      setAuthPill("Auth check failed", "error");
      setWorkspaceState(false);
      showDetail("user-info", {
        error: error.message,
        http_status: error.httpStatus || null,
        effective_status: error.status || null,
      });
    }
  }

  function login() {
    const redirect = encodeURIComponent(buildRedirectTarget());
    window.location.href =
      CFG.identity +
      "/authentication/login?provider=google&redirect=" +
      redirect;
  }

  async function logout() {
    try {
      await request(CFG.identity, "/authentication/logout", {
        method: "POST",
        allowStatuses: [200, 401],
      });
    } catch (error) {
      showToast("Logout request returned: " + error.message, "info");
    }
    clearWorkspaceState();
    setWorkspaceState(false);
    setAuthPill("Logged out", "idle");
    showDetail("user-info", "Not authenticated");
    showToast("Logged out", "info");
    window.history.replaceState({}, "", buildRedirectTarget());
  }

  function clearWorkspaceState() {
    STATE.user = null;
    STATE.campaigns = [];
    STATE.selectedCampaignId = null;
    STATE.selectedCampaign = null;
    STATE.projects = [];
    STATE.selectedProjectId = null;
    STATE.selectedProject = null;
    STATE.datasources = [];
    STATE.selectedDatasourceId = null;
    STATE.selectedDatasource = null;
    STATE.targets = [];
    STATE.selectedTargetId = null;
    STATE.selectedTarget = null;
    renderCampaigns();
    renderProjects();
    renderDatasources();
    renderTargets();
    showDetail("campaign-detail", "Select a campaign to inspect detail.");
    showDetail("project-detail", "Select a project to inspect detail.");
    showDetail("crisis-detail", "Select a project to inspect crisis config.");
    showDetail("datasource-detail", "Select a datasource to inspect detail.");
    showDetail("target-detail", "Select a target to inspect detail.");
    updateContextBar();
  }

  function updateContextBar() {
    const parts = ["Campaigns"];
    if (STATE.selectedCampaign) {
      parts.push(STATE.selectedCampaign.name || STATE.selectedCampaign.id);
      parts.push("Projects");
    }
    if (STATE.selectedProject) {
      parts.push(STATE.selectedProject.name || STATE.selectedProject.id);
      parts.push("Datasources");
    }
    if (STATE.selectedDatasource) {
      parts.push(STATE.selectedDatasource.name || STATE.selectedDatasource.id);
      parts.push("Targets");
    }
    el["context-bar"].textContent = parts.join(" -> ");
  }

  function renderTable(containerId, columns, rows) {
    if (!rows.length) {
      el[containerId].innerHTML = '<div class="muted">No items yet.</div>';
      return;
    }
    const head = columns.map(function (column) {
      return "<th>" + escapeHtml(column) + "</th>";
    });
    el[containerId].innerHTML =
      "<table><thead><tr>" +
      head.join("") +
      "</tr></thead><tbody>" +
      rows.join("") +
      "</tbody></table>";
  }

  function badge(value) {
    return '<span class="muted">' + escapeHtml(value || "-") + "</span>";
  }

  function campaignRow(item) {
    const selected = item.id === STATE.selectedCampaignId ? " selected" : "";
    return (
      '<tr class="' +
      selected +
      '">' +
      "<td>" +
      escapeHtml(item.name) +
      "</td>" +
      "<td>" +
      badge(item.status) +
      "</td>" +
      "<td>" +
      escapeHtml(item.start_date || "-") +
      "</td>" +
      "<td>" +
      '<div class="row-actions">' +
      '<button class="row-btn" type="button" onclick="App.selectCampaign(\'' +
      item.id +
      "')\">Select</button>" +
      '<button class="row-btn" type="button" onclick="App.editCampaign(\'' +
      item.id +
      "')\">Edit</button>" +
      '<button class="row-btn danger" type="button" onclick="App.archiveCampaign(\'' +
      item.id +
      "')\">Archive</button>" +
      "</div></td>" +
      "</tr>"
    );
  }

  function projectRow(item) {
    const selected = item.id === STATE.selectedProjectId ? " selected" : "";
    return (
      '<tr class="' +
      selected +
      '">' +
      "<td>" +
      escapeHtml(item.name) +
      "</td>" +
      "<td>" +
      escapeHtml(item.entity_type + " / " + item.entity_name) +
      "</td>" +
      "<td>" +
      badge(item.status) +
      "</td>" +
      "<td>" +
      '<div class="row-actions">' +
      '<button class="row-btn" type="button" onclick="App.selectProject(\'' +
      item.id +
      "')\">Select</button>" +
      '<button class="row-btn" type="button" onclick="App.editProject(\'' +
      item.id +
      "')\">Edit</button>" +
      '<button class="row-btn danger" type="button" onclick="App.archiveProject(\'' +
      item.id +
      "')\">Archive</button>" +
      "</div></td>" +
      "</tr>"
    );
  }

  function datasourceRow(item) {
    const selected = item.id === STATE.selectedDatasourceId ? " selected" : "";
    return (
      '<tr class="' +
      selected +
      '">' +
      "<td>" +
      escapeHtml(item.name) +
      "</td>" +
      "<td>" +
      escapeHtml(item.source_type) +
      "</td>" +
      "<td>" +
      badge(item.status) +
      "</td>" +
      "<td>" +
      '<div class="row-actions">' +
      '<button class="row-btn" type="button" onclick="App.selectDatasource(\'' +
      item.id +
      "')\">Select</button>" +
      '<button class="row-btn" type="button" onclick="App.editDatasource(\'' +
      item.id +
      "')\">Edit</button>" +
      '<button class="row-btn danger" type="button" onclick="App.archiveDatasource(\'' +
      item.id +
      "')\">Archive</button>" +
      "</div></td>" +
      "</tr>"
    );
  }

  function targetRow(item) {
    const selected = item.id === STATE.selectedTargetId ? " selected" : "";
    return (
      '<tr class="' +
      selected +
      '">' +
      "<td>" +
      escapeHtml(item.target_type) +
      "</td>" +
      "<td>" +
      escapeHtml(item.label || "-") +
      "</td>" +
      "<td>" +
      escapeHtml((item.values || []).slice(0, 3).join(", ")) +
      "</td>" +
      "<td>" +
      '<div class="row-actions">' +
      '<button class="row-btn" type="button" onclick="App.selectTarget(\'' +
      item.id +
      "')\">Select</button>" +
      '<button class="row-btn" type="button" onclick="App.editTarget(\'' +
      item.id +
      "')\">Edit</button>" +
      '<button class="row-btn danger" type="button" onclick="App.deleteTarget(\'' +
      item.id +
      "')\">Delete</button>" +
      "</div></td>" +
      "</tr>"
    );
  }

  function renderCampaigns() {
    renderTable(
      "campaign-list",
      ["Name", "Status", "Start", "Actions"],
      STATE.campaigns.map(campaignRow)
    );
  }

  function renderProjects() {
    if (!STATE.selectedCampaignId) {
      el["project-list"].innerHTML = '<div class="muted">Select a campaign first.</div>';
      return;
    }
    renderTable(
      "project-list",
      ["Name", "Entity", "Status", "Actions"],
      STATE.projects.map(projectRow)
    );
  }

  function renderDatasources() {
    if (!STATE.selectedProjectId) {
      el["datasource-list"].innerHTML = '<div class="muted">Select a project first.</div>';
      return;
    }
    renderTable(
      "datasource-list",
      ["Name", "Source Type", "Status", "Actions"],
      STATE.datasources.map(datasourceRow)
    );
  }

  function renderTargets() {
    if (!STATE.selectedDatasourceId) {
      el["target-list"].innerHTML = '<div class="muted">Select a datasource first.</div>';
      return;
    }
    renderTable(
      "target-list",
      ["Target Type", "Label", "Values", "Actions"],
      STATE.targets.map(targetRow)
    );
  }

  async function loadCampaigns() {
    if (!STATE.user) {
      return;
    }
    const result = await request(CFG.project, "/campaigns?page=1&limit=100");
    STATE.campaigns = result.data ? result.data.campaigns || [] : [];
    if (
      STATE.selectedCampaignId &&
      !STATE.campaigns.some(function (item) {
        return item.id === STATE.selectedCampaignId;
      })
    ) {
      STATE.selectedCampaignId = null;
      STATE.selectedCampaign = null;
      STATE.projects = [];
      STATE.selectedProjectId = null;
      STATE.selectedProject = null;
      STATE.datasources = [];
      STATE.selectedDatasourceId = null;
      STATE.selectedDatasource = null;
      STATE.targets = [];
    }
    renderCampaigns();
    renderProjects();
    renderDatasources();
    renderTargets();
    updateContextBar();
  }

  async function saveCampaign(event) {
    event.preventDefault();
    const editId = el["campaign-edit-id"].value;
    const payload = {
      name: el["campaign-name"].value.trim(),
      description: el["campaign-description"].value.trim(),
    };
    if (el["campaign-start"].value) {
      payload.start_date = new Date(el["campaign-start"].value).toISOString();
    }
    if (el["campaign-end"].value) {
      payload.end_date = new Date(el["campaign-end"].value).toISOString();
    }
    if (editId && el["campaign-status"].value) {
      payload.status = el["campaign-status"].value;
    }
    if (!editId && !payload.name) {
      showToast("Campaign name is required", "error");
      return;
    }
    const path = editId ? "/campaigns/" + editId : "/campaigns";
    const method = editId ? "PUT" : "POST";
    await request(CFG.project, path, { method: method, body: payload });
    showToast(editId ? "Campaign updated" : "Campaign created", "success");
    resetCampaignForm();
    await loadCampaigns();
    if (editId || STATE.selectedCampaignId) {
      await selectCampaign(editId || STATE.selectedCampaignId);
    }
  }

  function resetCampaignForm() {
    el["campaign-edit-id"].value = "";
    el["campaign-name"].value = "";
    el["campaign-status"].value = "";
    el["campaign-description"].value = "";
    el["campaign-start"].value = "";
    el["campaign-end"].value = "";
  }

  async function selectCampaign(id) {
    const result = await request(CFG.project, "/campaigns/" + id);
    STATE.selectedCampaignId = id;
    STATE.selectedCampaign = result.data.campaign;
    showDetail("campaign-detail", STATE.selectedCampaign);
    STATE.selectedProjectId = null;
    STATE.selectedProject = null;
    STATE.datasources = [];
    STATE.selectedDatasourceId = null;
    STATE.selectedDatasource = null;
    STATE.targets = [];
    renderCampaigns();
    updateContextBar();
    await loadProjects();
  }

  function editCampaign(id) {
    const item =
      STATE.campaigns.find(function (campaign) {
        return campaign.id === id;
      }) || STATE.selectedCampaign;
    if (!item) {
      return;
    }
    el["campaign-edit-id"].value = item.id;
    el["campaign-name"].value = item.name || "";
    el["campaign-status"].value = item.status || "";
    el["campaign-description"].value = item.description || "";
    el["campaign-start"].value = formatDateTimeLocal(item.start_date);
    el["campaign-end"].value = formatDateTimeLocal(item.end_date);
  }

  async function archiveCampaign(id) {
    if (!window.confirm("Archive this campaign?")) {
      return;
    }
    await request(CFG.project, "/campaigns/" + id, { method: "DELETE" });
    showToast("Campaign archived", "success");
    if (STATE.selectedCampaignId === id) {
      STATE.selectedCampaignId = null;
      STATE.selectedCampaign = null;
      STATE.projects = [];
      STATE.selectedProjectId = null;
      STATE.selectedProject = null;
      STATE.datasources = [];
      STATE.selectedDatasourceId = null;
      STATE.selectedDatasource = null;
      STATE.targets = [];
      showDetail("campaign-detail", "Select a campaign to inspect detail.");
      showDetail("project-detail", "Select a project to inspect detail.");
      showDetail("crisis-detail", "Select a project to inspect crisis config.");
      showDetail("datasource-detail", "Select a datasource to inspect detail.");
      showDetail("target-detail", "Select a target to inspect detail.");
    }
    resetCampaignForm();
    await loadCampaigns();
  }

  async function loadProjects() {
    if (!STATE.selectedCampaignId) {
      renderProjects();
      return;
    }
    const result = await request(
      CFG.project,
      "/campaigns/" + STATE.selectedCampaignId + "/projects?page=1&limit=100"
    );
    STATE.projects = result.data ? result.data.projects || [] : [];
    if (
      STATE.selectedProjectId &&
      !STATE.projects.some(function (item) {
        return item.id === STATE.selectedProjectId;
      })
    ) {
      STATE.selectedProjectId = null;
      STATE.selectedProject = null;
      STATE.datasources = [];
      STATE.selectedDatasourceId = null;
      STATE.selectedDatasource = null;
      STATE.targets = [];
    }
    renderProjects();
    renderDatasources();
    renderTargets();
    updateContextBar();
  }

  async function saveProject(event) {
    event.preventDefault();
    if (!STATE.selectedCampaignId) {
      showToast("Select a campaign first", "error");
      return;
    }
    const editId = el["project-edit-id"].value;
    const payload = {
      name: el["project-name"].value.trim(),
      description: el["project-description"].value.trim(),
      brand: el["project-brand"].value.trim(),
      entity_type: el["project-entity-type"].value,
      entity_name: el["project-entity-name"].value.trim(),
    };
    if (editId && el["project-status"].value) {
      payload.status = el["project-status"].value;
    }
    if (!editId && (!payload.name || !payload.entity_type || !payload.entity_name)) {
      showToast("Project name, entity type, and entity name are required", "error");
      return;
    }
    const path = editId
      ? "/projects/" + editId
      : "/campaigns/" + STATE.selectedCampaignId + "/projects";
    const method = editId ? "PUT" : "POST";
    await request(CFG.project, path, { method: method, body: payload });
    showToast(editId ? "Project updated" : "Project created", "success");
    resetProjectForm();
    await loadProjects();
    if (editId || STATE.selectedProjectId) {
      await selectProject(editId || STATE.selectedProjectId);
    }
  }

  function resetProjectForm() {
    el["project-edit-id"].value = "";
    el["project-name"].value = "";
    el["project-brand"].value = "";
    el["project-entity-type"].value = "product";
    el["project-entity-name"].value = "";
    el["project-description"].value = "";
    el["project-status"].value = "";
  }

  async function selectProject(id) {
    const result = await request(CFG.project, "/projects/" + id);
    STATE.selectedProjectId = id;
    STATE.selectedProject = result.data.project;
    showDetail("project-detail", STATE.selectedProject);
    STATE.selectedDatasourceId = null;
    STATE.selectedDatasource = null;
    STATE.targets = [];
    renderProjects();
    updateContextBar();
    await Promise.all([loadCrisisConfig(), loadDatasources()]);
  }

  function editProject(id) {
    const item =
      STATE.projects.find(function (project) {
        return project.id === id;
      }) || STATE.selectedProject;
    if (!item) {
      return;
    }
    el["project-edit-id"].value = item.id;
    el["project-name"].value = item.name || "";
    el["project-brand"].value = item.brand || "";
    el["project-entity-type"].value = item.entity_type || "product";
    el["project-entity-name"].value = item.entity_name || "";
    el["project-description"].value = item.description || "";
    el["project-status"].value = item.status || "";
  }

  async function archiveProject(id) {
    if (!window.confirm("Archive this project?")) {
      return;
    }
    await request(CFG.project, "/projects/" + id, { method: "DELETE" });
    showToast("Project archived", "success");
    if (STATE.selectedProjectId === id) {
      STATE.selectedProjectId = null;
      STATE.selectedProject = null;
      STATE.datasources = [];
      STATE.selectedDatasourceId = null;
      STATE.selectedDatasource = null;
      STATE.targets = [];
      showDetail("project-detail", "Select a project to inspect detail.");
      showDetail("crisis-detail", "Select a project to inspect crisis config.");
      showDetail("datasource-detail", "Select a datasource to inspect detail.");
      showDetail("target-detail", "Select a target to inspect detail.");
    }
    resetProjectForm();
    await loadProjects();
  }

  function loadCrisisSample() {
    el["crisis-json"].value = pretty(CRISIS_SAMPLE);
  }

  async function loadCrisisConfig() {
    if (!STATE.selectedProjectId) {
      showDetail("crisis-detail", "Select a project to inspect crisis config.");
      return;
    }
    try {
      const result = await request(
        CFG.project,
        "/projects/" + STATE.selectedProjectId + "/crisis-config"
      );
      showDetail("crisis-detail", result.data.crisis_config);
      el["crisis-json"].value = pretty(result.data.crisis_config);
    } catch (error) {
      if (error.status === 400 || error.status === 404 || error.status === 500) {
        showDetail("crisis-detail", {
          message: "No crisis config loaded",
          status: error.status,
          response: error.responseBody || null,
        });
      } else {
        throw error;
      }
    }
  }

  async function saveCrisisConfig(event) {
    event.preventDefault();
    if (!STATE.selectedProjectId) {
      showToast("Select a project first", "error");
      return;
    }
    let payload;
    try {
      payload = JSON.parse(el["crisis-json"].value);
    } catch (error) {
      showToast("Crisis config JSON is invalid", "error");
      return;
    }
    await request(
      CFG.project,
      "/projects/" + STATE.selectedProjectId + "/crisis-config",
      { method: "PUT", body: payload }
    );
    showToast("Crisis config saved", "success");
    await loadCrisisConfig();
  }

  async function deleteCrisisConfig() {
    if (!STATE.selectedProjectId) {
      showToast("Select a project first", "error");
      return;
    }
    if (!window.confirm("Delete crisis config for the selected project?")) {
      return;
    }
    await request(
      CFG.project,
      "/projects/" + STATE.selectedProjectId + "/crisis-config",
      { method: "DELETE" }
    );
    showToast("Crisis config deleted", "success");
    showDetail("crisis-detail", "Crisis config deleted.");
    loadCrisisSample();
  }

  async function loadDatasources() {
    if (!STATE.selectedProjectId) {
      renderDatasources();
      return;
    }
    const result = await request(
      CFG.ingest,
      "/datasources?project_id=" + encodeURIComponent(STATE.selectedProjectId) + "&page=1&limit=100"
    );
    STATE.datasources = result.data ? result.data.data_sources || [] : [];
    if (
      STATE.selectedDatasourceId &&
      !STATE.datasources.some(function (item) {
        return item.id === STATE.selectedDatasourceId;
      })
    ) {
      STATE.selectedDatasourceId = null;
      STATE.selectedDatasource = null;
      STATE.targets = [];
    }
    renderDatasources();
    renderTargets();
    updateContextBar();
  }

  async function saveDatasource(event) {
    event.preventDefault();
    if (!STATE.selectedProjectId) {
      showToast("Select a project first", "error");
      return;
    }
    const editId = el["datasource-edit-id"].value;
    const payload = {
      name: el["datasource-name"].value.trim(),
      description: el["datasource-description"].value.trim(),
      source_type: el["datasource-source-type"].value,
      source_category: el["datasource-source-category"].value,
    };
    const crawlMode = el["datasource-crawl-mode"].value;
    const crawlInterval = Number(el["datasource-crawl-interval"].value);
    if (!editId) {
      payload.project_id = STATE.selectedProjectId;
      payload.crawl_mode = crawlMode;
      payload.crawl_interval_minutes = crawlInterval;
    }
    if (editId) {
      delete payload.source_type;
      delete payload.source_category;
    } else if (payload.source_category === "CRAWL") {
      payload.crawl_mode = crawlMode;
      payload.crawl_interval_minutes = crawlInterval;
    }
    const configJson = parseOptionalJson(el["datasource-config"].value, "Config");
    const accountRefJson = parseOptionalJson(
      el["datasource-account-ref"].value,
      "Account Ref"
    );
    if (configJson !== undefined) {
      payload.config = configJson;
    }
    if (accountRefJson !== undefined) {
      payload.account_ref = accountRefJson;
    }
    const path = editId ? "/datasources/" + editId : "/datasources";
    const method = editId ? "PUT" : "POST";
    await request(CFG.ingest, path, { method: method, body: payload });
    showToast(editId ? "Datasource updated" : "Datasource created", "success");
    resetDatasourceForm();
    await loadDatasources();
    if (editId || STATE.selectedDatasourceId) {
      await selectDatasource(editId || STATE.selectedDatasourceId);
    }
  }

  function resetDatasourceForm() {
    el["datasource-edit-id"].value = "";
    el["datasource-name"].value = "";
    el["datasource-source-type"].value = "TIKTOK";
    el["datasource-source-category"].value = "CRAWL";
    el["datasource-crawl-mode"].value = "NORMAL";
    el["datasource-crawl-interval"].value = "11";
    el["datasource-description"].value = "";
    el["datasource-config"].value = "";
    el["datasource-account-ref"].value = "";
  }

  async function selectDatasource(id) {
    const result = await request(CFG.ingest, "/datasources/" + id);
    STATE.selectedDatasourceId = id;
    STATE.selectedDatasource = result.data.data_source;
    showDetail("datasource-detail", STATE.selectedDatasource);
    STATE.selectedTargetId = null;
    STATE.selectedTarget = null;
    renderDatasources();
    updateContextBar();
    await loadTargets();
  }

  function editDatasource(id) {
    const item =
      STATE.datasources.find(function (datasource) {
        return datasource.id === id;
      }) || STATE.selectedDatasource;
    if (!item) {
      return;
    }
    el["datasource-edit-id"].value = item.id;
    el["datasource-name"].value = item.name || "";
    el["datasource-source-type"].value = item.source_type || "TIKTOK";
    el["datasource-source-category"].value = item.source_category || "CRAWL";
    el["datasource-crawl-mode"].value = item.crawl_mode || "NORMAL";
    el["datasource-crawl-interval"].value = item.crawl_interval_minutes || 11;
    el["datasource-description"].value = item.description || "";
    el["datasource-config"].value = item.config ? pretty(item.config) : "";
    el["datasource-account-ref"].value = item.account_ref ? pretty(item.account_ref) : "";
  }

  async function archiveDatasource(id) {
    if (!window.confirm("Archive this datasource?")) {
      return;
    }
    await request(CFG.ingest, "/datasources/" + id, { method: "DELETE" });
    showToast("Datasource archived", "success");
    if (STATE.selectedDatasourceId === id) {
      STATE.selectedDatasourceId = null;
      STATE.selectedDatasource = null;
      STATE.targets = [];
      showDetail("datasource-detail", "Select a datasource to inspect detail.");
      showDetail("target-detail", "Select a target to inspect detail.");
    }
    resetDatasourceForm();
    await loadDatasources();
  }

  async function loadTargets() {
    if (!STATE.selectedDatasourceId) {
      renderTargets();
      return;
    }
    const result = await request(
      CFG.ingest,
      "/datasources/" + STATE.selectedDatasourceId + "/targets"
    );
    STATE.targets = result.data ? result.data.targets || [] : [];
    if (
      STATE.selectedTargetId &&
      !STATE.targets.some(function (item) {
        return item.id === STATE.selectedTargetId;
      })
    ) {
      STATE.selectedTargetId = null;
      STATE.selectedTarget = null;
    }
    renderTargets();
  }

  async function saveTarget(event) {
    event.preventDefault();
    if (!STATE.selectedDatasourceId) {
      showToast("Select a datasource first", "error");
      return;
    }
    const editId = el["target-edit-id"].value;
    const values = el["target-values"].value
      .split("\n")
      .map(function (item) {
        return item.trim();
      })
      .filter(Boolean);
    const payload = {
      label: el["target-label"].value.trim(),
      priority: Number(el["target-priority"].value),
      crawl_interval_minutes: Number(el["target-crawl-interval"].value),
      is_active: el["target-is-active"].checked,
    };
    if (values.length) {
      payload.values = values;
    }
    const platformMeta = parseOptionalJson(
      el["target-platform-meta"].value,
      "Platform Meta"
    );
    if (platformMeta !== undefined) {
      payload.platform_meta = platformMeta;
    }
    const path = editId
      ? "/datasources/" + STATE.selectedDatasourceId + "/targets/" + editId
      : "/datasources/" +
        STATE.selectedDatasourceId +
        "/targets/" +
        el["target-type"].value;
    const method = editId ? "PUT" : "POST";
    await request(CFG.ingest, path, { method: method, body: payload });
    showToast(editId ? "Target updated" : "Target created", "success");
    resetTargetForm();
    await loadTargets();
    if (editId || STATE.selectedTargetId) {
      await selectTarget(editId || STATE.selectedTargetId);
    }
  }

  function resetTargetForm() {
    el["target-edit-id"].value = "";
    el["target-type"].value = "keywords";
    el["target-priority"].value = "1";
    el["target-crawl-interval"].value = "11";
    el["target-label"].value = "";
    el["target-values"].value = "";
    el["target-platform-meta"].value = "";
    el["target-is-active"].checked = true;
  }

  function normalizedTargetType(value) {
    const map = {
      KEYWORD: "keywords",
      PROFILE: "profiles",
      POST_URL: "posts",
    };
    return map[value] || value;
  }

  async function selectTarget(id) {
    const result = await request(
      CFG.ingest,
      "/datasources/" + STATE.selectedDatasourceId + "/targets/" + id
    );
    STATE.selectedTargetId = id;
    STATE.selectedTarget = result.data.target;
    showDetail("target-detail", STATE.selectedTarget);
    renderTargets();
  }

  async function editTarget(id) {
    await selectTarget(id);
    const item = STATE.selectedTarget;
    if (!item) {
      return;
    }
    el["target-edit-id"].value = item.id;
    el["target-type"].value = normalizedTargetType(item.target_type);
    el["target-priority"].value = item.priority != null ? item.priority : 1;
    el["target-crawl-interval"].value =
      item.crawl_interval_minutes != null ? item.crawl_interval_minutes : 11;
    el["target-label"].value = item.label || "";
    el["target-values"].value = toLines(item.values);
    el["target-platform-meta"].value = item.platform_meta ? pretty(item.platform_meta) : "";
    el["target-is-active"].checked = Boolean(item.is_active);
  }

  async function deleteTarget(id) {
    if (!window.confirm("Delete this target?")) {
      return;
    }
    await request(
      CFG.ingest,
      "/datasources/" + STATE.selectedDatasourceId + "/targets/" + id,
      { method: "DELETE" }
    );
    showToast("Target deleted", "success");
    if (STATE.selectedTargetId === id) {
      STATE.selectedTargetId = null;
      STATE.selectedTarget = null;
      showDetail("target-detail", "Select a target to inspect detail.");
    }
    resetTargetForm();
    await loadTargets();
  }

  // ================================================================
  // KNOWLEDGE — CHAT (RAG)
  // ================================================================

  function newConversation() {
    STATE.conversationId = null;
    STATE.chatMessages = [];
    el["chat-msgs"].innerHTML = '';
    el["chat-suggestions"].classList.add("hidden");
    el["chat-input"].value = '';
    showToast("New conversation started", "info");
  }

  function appendChatMessage(role, content, citations) {
    const div = document.createElement("div");
    div.className = "chat-msg chat-msg-" + role;
    const head = document.createElement("div");
    head.className = "chat-msg-role";
    head.textContent = role === "user" ? "You" : "AI";
    div.appendChild(head);
    const text = document.createElement("div");
    text.className = "chat-msg-text";
    text.textContent = content;
    div.appendChild(text);
    if (citations && citations.length) {
      const cit = document.createElement("div");
      cit.className = "chat-citations muted";
      cit.textContent = "Sources: " + citations.map(function(c) { return c.content ? c.content.slice(0, 60) + "…" : c.id; }).join(" | ");
      div.appendChild(cit);
    }
    el["chat-msgs"].appendChild(div);
    el["chat-msgs"].scrollTop = el["chat-msgs"].scrollHeight;
  }

  async function sendChat(event) {
    event.preventDefault();
    const msg = el["chat-input"].value.trim();
    if (!msg) { return; }
    if (!STATE.selectedCampaignId) {
      showToast("Select a campaign first", "error");
      return;
    }
    appendChatMessage("user", msg, null);
    el["chat-input"].value = "";
    el["chat-input"].disabled = true;
    const body = {
      campaign_id: STATE.selectedCampaignId,
      message: msg,
    };
    if (STATE.conversationId) {
      body.conversation_id = STATE.conversationId;
    }
    try {
      const result = await request(CFG.knowledge, "/chat", { method: "POST", body: body });
      const data = result.data || {};
      STATE.conversationId = data.conversation_id || STATE.conversationId;
      appendChatMessage("assistant", data.message || "", data.citations || []);
      if (data.suggestions && data.suggestions.length) {
        renderSuggestions(data.suggestions);
      }
    } catch (error) {
      appendChatMessage("assistant", "⚠ " + error.message, null);
    } finally {
      el["chat-input"].disabled = false;
      el["chat-input"].focus();
    }
  }

  async function loadSuggestions() {
    if (!STATE.selectedCampaignId) {
      showToast("Select a campaign first", "error");
      return;
    }
    const result = await request(CFG.knowledge, "/campaigns/" + STATE.selectedCampaignId + "/suggestions");
    const sugs = (result.data && result.data.suggestions) || [];
    renderSuggestions(sugs);
  }

  function renderSuggestions(list) {
    el["chat-suggestions"].innerHTML = "";
    if (!list.length) {
      el["chat-suggestions"].classList.add("hidden");
      return;
    }
    list.slice(0, 5).forEach(function(s) {
      const btn = document.createElement("button");
      btn.className = "suggestion-chip";
      btn.type = "button";
      btn.textContent = typeof s === "string" ? s : s.question || s.text || JSON.stringify(s);
      btn.addEventListener("click", function() {
        el["chat-input"].value = btn.textContent;
        el["chat-input"].focus();
      });
      el["chat-suggestions"].appendChild(btn);
    });
    el["chat-suggestions"].classList.remove("hidden");
  }

  // ================================================================
  // KNOWLEDGE — SEARCH
  // ================================================================

  async function doSearch(event) {
    event.preventDefault();
    if (!STATE.selectedCampaignId) {
      showToast("Select a campaign first", "error");
      return;
    }
    const body = {
      campaign_id: STATE.selectedCampaignId,
      query: el["search-query"].value.trim(),
    };
    const filters = {};
    if (el["search-sentiment"].value) filters.sentiment = el["search-sentiment"].value;
    if (el["search-platform"].value) filters.platform = el["search-platform"].value;
    if (el["search-date-from"].value) filters.date_from = new Date(el["search-date-from"].value).toISOString();
    if (el["search-date-to"].value) filters.date_to = new Date(el["search-date-to"].value).toISOString();
    if (Object.keys(filters).length) body.filters = filters;
    const result = await request(CFG.knowledge, "/search", { method: "POST", body: body });
    showDetail("search-result", result.data || result.body);
    showToast("Search complete", "success");
  }

  // ================================================================
  // KNOWLEDGE — AI REPORTS
  // ================================================================

  async function generateReport(event) {
    event.preventDefault();
    if (!STATE.selectedCampaignId) {
      showToast("Select a campaign first", "error");
      return;
    }
    const body = {
      campaign_id: STATE.selectedCampaignId,
      report_type: el["report-type"].value,
    };
    const result = await request(CFG.knowledge, "/reports/generate", { method: "POST", body: body });
    const data = result.data || {};
    STATE.currentReportId = data.report_id || data.id;
    el["report-id-display"].textContent = STATE.currentReportId || "?";
    el["report-status-display"].textContent = data.status || "PROCESSING";
    el["report-status-row"].classList.remove("hidden");
    el["report-download-row"].classList.add("hidden");
    showDetail("report-detail", data);
    showToast("Report generation triggered", "success");
    if (STATE.currentReportId) {
      startReportPolling();
    }
  }

  function startReportPolling() {
    if (STATE.reportPollTimer) clearInterval(STATE.reportPollTimer);
    STATE.reportPollTimer = setInterval(function() {
      refreshReportStatus().catch(handleUiError);
    }, 3000);
  }

  async function refreshReportStatus() {
    if (!STATE.currentReportId) {
      showToast("No active report", "error");
      return;
    }
    const result = await request(CFG.knowledge, "/reports/" + STATE.currentReportId);
    const data = result.data || {};
    const status = data.status || "?";
    el["report-status-display"].textContent = status;
    el["report-status-row"].classList.remove("hidden");
    showDetail("report-detail", data);
    if (status === "COMPLETED") {
      if (STATE.reportPollTimer) { clearInterval(STATE.reportPollTimer); STATE.reportPollTimer = null; }
      // fetch download link
      try {
        const dlResult = await request(CFG.knowledge, "/reports/" + STATE.currentReportId + "/download");
        const url = (dlResult.data && dlResult.data.url) || (dlResult.body && dlResult.body.url) || "#";
        el["report-download-link"].href = url;
        el["report-download-row"].classList.remove("hidden");
        showToast("Report ready — download available", "success");
      } catch(e) { /* ignore */ }
    } else if (status === "FAILED") {
      if (STATE.reportPollTimer) { clearInterval(STATE.reportPollTimer); STATE.reportPollTimer = null; }
      showToast("Report generation failed", "error");
    }
  }

  // ================================================================
  // SCRAPER — TASK SUBMISSION
  // ================================================================

  async function submitScraperTask(event) {
    event.preventDefault();
    const platform = el["scraper-platform"].value;
    const action = el["scraper-action"].value.trim();
    let params;
    try {
      params = JSON.parse(el["scraper-params"].value);
    } catch(e) {
      showToast("Params JSON invalid", "error");
      return;
    }
    const body = { action: action, params: params };
    const result = await request(CFG.scraper, "/tasks/" + platform, { method: "POST", body: body });
    const data = result.data || result.body || {};
    STATE.lastScraperTaskId = data.task_id || data.id;
    if (STATE.lastScraperTaskId) {
      el["scraper-task-id-display"].textContent = STATE.lastScraperTaskId;
      el["scraper-task-id-row"].classList.remove("hidden");
    }
    showDetail("scraper-result", data);
    showToast("Scraper task submitted", "success");
  }

  async function fetchScraperResult() {
    if (!STATE.lastScraperTaskId) {
      showToast("No task ID available", "error");
      return;
    }
    const result = await request(CFG.scraper, "/tasks/" + STATE.lastScraperTaskId + "/result");
    showDetail("scraper-result", result.data || result.body);
    showToast("Result fetched", "success");
  }

  async function listScraperTasks() {
    const result = await request(CFG.scraper, "/tasks");
    showDetail("scraper-result", result.data || result.body);
    showToast("Tasks listed", "success");
  }

  // ================================================================
  // NOTIFICATION — WEBSOCKET
  // ================================================================

  function wsConnect() {
    if (STATE.ws && STATE.ws.readyState === WebSocket.OPEN) {
      showToast("Already connected", "info");
      return;
    }
    if (STATE.wsReconnectTimer) { clearTimeout(STATE.wsReconnectTimer); STATE.wsReconnectTimer = null; }
    setWsPill("Connecting…", "idle");
    try {
      STATE.ws = new WebSocket(CFG.notificationWs);
    } catch (e) {
      setWsPill("Error", "error");
      showToast("WebSocket error: " + e.message, "error");
      return;
    }
    STATE.ws.addEventListener("open", function() {
      STATE.wsReconnectAttempts = 0;
      setWsPill("Connected", "ok");
      el["ws-connect-btn"].classList.add("hidden");
      el["ws-disconnect-btn"].classList.remove("hidden");
      appendNotification("system", "WebSocket connected");
      showToast("WebSocket connected", "success");
    });
    STATE.ws.addEventListener("message", function(event) {
      var data;
      try { data = JSON.parse(event.data); } catch(e) { data = { raw: event.data }; }
      appendNotification(data.type || "message", data.message || event.data, data);
    });
    STATE.ws.addEventListener("close", function(event) {
      setWsPill("Disconnected", "idle");
      el["ws-connect-btn"].classList.remove("hidden");
      el["ws-disconnect-btn"].classList.add("hidden");
      appendNotification("system", "WebSocket disconnected (code " + event.code + ")");
      if (!event.wasClean) {
        scheduleWsReconnect();
      }
    });
    STATE.ws.addEventListener("error", function() {
      setWsPill("Error", "error");
      appendNotification("error", "WebSocket error");
    });
  }

  function wsDisconnect() {
    if (STATE.wsReconnectTimer) { clearTimeout(STATE.wsReconnectTimer); STATE.wsReconnectTimer = null; }
    STATE.wsReconnectAttempts = 0;
    if (STATE.ws) {
      STATE.ws.close(1000, "Manual disconnect");
      STATE.ws = null;
    }
    setWsPill("Disconnected", "idle");
    el["ws-connect-btn"].classList.remove("hidden");
    el["ws-disconnect-btn"].classList.add("hidden");
    showToast("WebSocket disconnected", "info");
  }

  function scheduleWsReconnect() {
    STATE.wsReconnectAttempts++;
    if (STATE.wsReconnectAttempts > 6) return;
    const delay = Math.min(1000 * Math.pow(2, STATE.wsReconnectAttempts - 1), 30000);
    setWsPill("Reconnecting in " + (delay / 1000).toFixed(0) + "s…", "idle");
    STATE.wsReconnectTimer = setTimeout(function() {
      if (STATE.user) wsConnect();
    }, delay);
  }

  function setWsPill(msg, kind) {
    el["ws-pill"].textContent = msg;
    el["ws-pill"].className = "status-pill status-" + kind;
  }

  function appendNotification(type, message, data) {
    var feed = el["notification-feed"];
    // Remove the placeholder if present
    var placeholder = feed.querySelector(".muted");
    if (placeholder) placeholder.remove();
    var item = document.createElement("div");
    item.className = "noti-item noti-" + (type || "message");
    var ts = new Date().toLocaleTimeString();
    item.innerHTML =
      '<span class="noti-ts">' + escapeHtml(ts) + '</span>' +
      '<span class="noti-type">' + escapeHtml(type || "msg") + '</span>' +
      '<span class="noti-msg">' + escapeHtml(message || "") + '</span>';
    if (data && typeof data === "object") {
      var detail = document.createElement("pre");
      detail.className = "noti-data";
      detail.textContent = JSON.stringify(data, null, 2);
      item.appendChild(detail);
    }
    feed.insertBefore(item, feed.firstChild);
    // Cap at 50 items
    while (feed.children.length > 50) feed.removeChild(feed.lastChild);
  }

  window.App = {
    selectCampaign: function (id) {
      selectCampaign(id).catch(handleUiError);
    },
    editCampaign: editCampaign,
    archiveCampaign: function (id) {
      archiveCampaign(id).catch(handleUiError);
    },
    selectProject: function (id) {
      selectProject(id).catch(handleUiError);
    },
    editProject: editProject,
    archiveProject: function (id) {
      archiveProject(id).catch(handleUiError);
    },
    selectDatasource: function (id) {
      selectDatasource(id).catch(handleUiError);
    },
    editDatasource: editDatasource,
    archiveDatasource: function (id) {
      archiveDatasource(id).catch(handleUiError);
    },
    selectTarget: function (id) {
      selectTarget(id).catch(handleUiError);
    },
    editTarget: function (id) {
      editTarget(id).catch(handleUiError);
    },
    deleteTarget: function (id) {
      deleteTarget(id).catch(handleUiError);
    },
  };

  function handleUiError(error) {
    console.error(error);
    showToast(error.message || "Unexpected error", "error");
    if (error.responseBody) {
      showDebug({
        error: error.message,
        http_status: error.httpStatus || null,
        effective_status: error.status || null,
        response_body: error.responseBody,
      });
    }
  }

  document.addEventListener("DOMContentLoaded", function () {
    init();
  });
})();
