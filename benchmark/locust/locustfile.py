import os
from locust import HttpUser, between, task


CAMPAIGN_ID = os.getenv("CAMPAIGN_ID", "5cc6763f-3ec5-4481-9c7b-597bd5bb6126")
PROJECT_ID = os.getenv("PROJECT_ID", "d25fe723-a407-4a77-ac69-1556749f51ff")


def analytics_path(path: str) -> str:
    separator = "&" if "?" in path else "?"
    return (
        f"{path}{separator}"
        f"campaignId={CAMPAIGN_ID}&projectIds={PROJECT_ID}&sourceKind=all"
    )


class MarketingDashboardUser(HttpUser):
    wait_time = between(0.4, 1.2)

    @task(1)
    def health(self):
        self.client.get("/api/health", name="health")

    @task(4)
    def dashboard_kpis(self):
        self.client.get(analytics_path("/api/analytics/kpis"), name="analytics_kpis")
        self.client.get(analytics_path("/api/analytics/platforms"), name="analytics_platforms")
        self.client.get(analytics_path("/api/analytics/sentiment"), name="analytics_sentiment")

    @task(3)
    def insight_feed(self):
        self.client.get(
            analytics_path("/api/analytics/posts?limit=20&offset=0&sort=engagement"),
            name="posts_engagement",
        )
        self.client.get(
            analytics_path("/api/analytics/posts?limit=20&offset=20&sort=engagement"),
            name="posts_page_2",
        )

    @task(2)
    def latest_posts(self):
        self.client.get(
            analytics_path("/api/analytics/posts?limit=20&offset=0&sort=time"),
            name="posts_latest",
        )

    @task(2)
    def keywords_and_project_stats(self):
        self.client.get(analytics_path("/api/analytics/keywords?limit=20"), name="analytics_keywords")
        self.client.get(analytics_path("/api/analytics/project-stats"), name="project_stats")
