import http from "k6/http";
import { check, sleep } from "k6";

const baseUrl = __ENV.BASE_URL || "https://smap.tantai.dev";
const campaignId = __ENV.CAMPAIGN_ID || "5cc6763f-3ec5-4481-9c7b-597bd5bb6126";
const projectId = __ENV.PROJECT_ID || "d25fe723-a407-4a77-ac69-1556749f51ff";

export const options = {
  vus: Number(__ENV.K6_VUS || "10"),
  duration: __ENV.K6_DURATION || "45s",
  thresholds: {
    http_req_failed: ["rate<0.01"],
    http_req_duration: ["p(95)<2500"]
  }
};

function withContext(path) {
  return path
    .replaceAll("{{campaignId}}", encodeURIComponent(campaignId))
    .replaceAll("{{projectId}}", encodeURIComponent(projectId));
}

const endpoints = [
  ["health", "/api/health"],
  ["analytics_kpis", "/api/analytics/kpis?campaignId={{campaignId}}&projectIds={{projectId}}&sourceKind=all"],
  ["analytics_platforms", "/api/analytics/platforms?campaignId={{campaignId}}&projectIds={{projectId}}&sourceKind=all"],
  ["analytics_sentiment", "/api/analytics/sentiment?campaignId={{campaignId}}&projectIds={{projectId}}&sourceKind=all"],
  ["analytics_keywords", "/api/analytics/keywords?campaignId={{campaignId}}&projectIds={{projectId}}&sourceKind=all&limit=20"],
  ["posts_latest", "/api/analytics/posts?campaignId={{campaignId}}&projectIds={{projectId}}&sourceKind=all&limit=20&offset=0&sort=time"],
  ["posts_engagement", "/api/analytics/posts?campaignId={{campaignId}}&projectIds={{projectId}}&sourceKind=all&limit=20&offset=0&sort=engagement"],
  ["posts_page_2", "/api/analytics/posts?campaignId={{campaignId}}&projectIds={{projectId}}&sourceKind=all&limit=20&offset=20&sort=engagement"],
  ["project_stats", "/api/analytics/project-stats?campaignId={{campaignId}}&projectIds={{projectId}}&sourceKind=all"]
];

export default function () {
  for (const [name, path] of endpoints) {
    const res = http.get(`${baseUrl}${withContext(path)}`, { tags: { endpoint: name } });
    check(res, {
      [`${name} status 200`]: (r) => r.status === 200,
      [`${name} json-ish`]: (r) => String(r.headers["Content-Type"] || "").includes("application/json")
    });
    sleep(0.2);
  }
}
