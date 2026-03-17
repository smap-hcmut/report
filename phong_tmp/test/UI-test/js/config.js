const PROD_API_ROOT = 'https://smap-api.tantai.dev';
const LOCAL_PROJECT_ROOT = 'http://localhost:8080';
const DEFAULT_PROJECT_BEARER_FALLBACK =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMzNmZmNmZDktZjc4Mi00OWE5LWE4YTYtMzU2M2JjMDI3NTBkIiwidXNlcm5hbWUiOiJkYW5ncXVvY3Bob25nMTcwM0BnbWFpbC5jb20iLCJyb2xlIjoiVklFV0VSIiwidHlwZSI6ImFjY2VzcyIsImV4cCI6MTc3NDM3NTgwMCwianRpIjoiMTc3Mzc3MTAwMDIyMjgwNzkxMyIsImlhdCI6MTc3Mzc3MTAwMCwibmJmIjoxNzczNzcxMDAwLCJzdWIiOiIzM2ZmY2ZkOS1mNzgyLTQ5YTktYThhNi0zNTYzYmMwMjc1MGQifQ.HVSzl485dUKJKAroYOIx4CSV1ev7YKS63S_JA5bfFYY';

export const CFG = {
  identityBase: `${PROD_API_ROOT}/identity/api/v1`,
  projectBase: `${PROD_API_ROOT}/project/api/v1`,
  projectFallbackBase: `${LOCAL_PROJECT_ROOT}/api/v1`,
  ingestBase: `${PROD_API_ROOT}/ingest/api/v1`,
  knowledgeBase: `${PROD_API_ROOT}/knowledge/api/v1`,
  scraperBase: `${PROD_API_ROOT}/scraper`,
  authModeLabel: 'Prod Project Cookie -> Local Project Cookie + Bearer',
  fallbackBearerToken: DEFAULT_PROJECT_BEARER_FALLBACK,
  authCookieName: 'smap_auth_token',
  enableTraceHeader: true,
  defaultPageSize: 10,
  requestTimeoutMs: 20000,
  swaggerUrls: {
    identity: `${PROD_API_ROOT}/identity/swagger/index.html`,
    project: `${PROD_API_ROOT}/project/swagger/index.html`,
    projectLocal: `${LOCAL_PROJECT_ROOT}/swagger/index.html`,
    ingest: `${PROD_API_ROOT}/ingest/swagger/index.html`,
    knowledge: `${PROD_API_ROOT}/knowledge/swagger/index.html`,
    scraper: `${PROD_API_ROOT}/scraper/docs`,
  },
};

export const ENUMS = {
  campaignStatus: ['ACTIVE', 'INACTIVE', 'ARCHIVED'],
  projectStatus: ['ACTIVE', 'PAUSED', 'ARCHIVED'],
  entityType: ['product', 'campaign', 'service', 'competitor', 'topic'],
  sourceType: ['TIKTOK', 'FACEBOOK', 'YOUTUBE', 'FILE_UPLOAD', 'WEBHOOK'],
  sourceCategory: ['CRAWL', 'PASSIVE'],
  crawlMode: ['NORMAL', 'SLEEP', 'CRISIS'],
  targetTypePath: ['keywords', 'profiles', 'posts'],
};
