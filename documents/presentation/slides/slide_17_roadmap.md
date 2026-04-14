# Slide 17: Kế hoạch phát triển - Hybrid Architecture
**Thời lượng**: 1 phút

---

## Nội dung hiển thị

```
KẾ HOẠCH PHÁT TRIỂN: MIGRATE LÊN HYBRID ARCHITECTURE

┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │           🏢 ON-PREMISE          ☁️  AWS CLOUD           │  │
│  │        (Core Services)        (Scalable Services)        │  │
│  │                                                          │  │
│  │  ┌────────────────┐           ┌────────────────────┐    │  │
│  │  │ • Identity     │           │ • Scraper Services │    │  │
│  │  │   Service      │           │   → AWS Lambda     │    │  │
│  │  │                │           │   (Serverless)     │    │  │
│  │  │ • Project      │           │                    │    │  │
│  │  │   Service      │           │ • FFmpeg/Playwright│    │  │
│  │  │                │           │   → ECS Fargate    │    │  │
│  │  │ • PostgreSQL   │           │                    │    │  │
│  │  │   (Identity,   │           │ • Analytics        │    │  │
│  │  │    Project)    │           │   → Lambda + SQS   │    │  │
│  │  └────────────────┘           └────────────────────┘    │  │
│  │                                                          │  │
│  │         ↕                              ↕                 │  │
│  │  ┌────────────────────────────────────────────────┐     │  │
│  │  │         SHARED INFRASTRUCTURE                  │     │  │
│  │  │                                                │     │  │
│  │  │  • MinIO → S3                                  │     │  │
│  │  │  • RabbitMQ → EventBridge + SQS                │     │  │
│  │  │  • MongoDB → DocumentDB                        │     │  │
│  │  │  • Redis → ElastiCache                         │     │  │
│  │  └────────────────────────────────────────────────┘     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    💡 LỢI ÍCH                            │  │
│  │                                                          │  │
│  │  ✅ Cost Optimization: Pay-per-use cho Scrapers         │  │
│  │  ✅ Auto-scaling: Lambda scale tự động theo workload    │  │
│  │  ✅ Managed Services: Giảm operational overhead         │  │
│  │  ✅ Security: Core data vẫn on-premise, tuân thủ GDPR   │  │
│  │  ✅ High Availability: Multi-AZ deployment              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                   📅 TIMELINE                            │  │
│  │                                                          │  │
│  │  PHASE 1 (3-6 tháng):                                   │  │
│  │    → Migrate Scrapers lên Lambda                        │  │
│  │    → MinIO → S3, RabbitMQ → EventBridge                 │  │
│  │                                                          │  │
│  │  PHASE 2 (6-12 tháng):                                  │  │
│  │    → Analytics Service lên Lambda                       │  │
│  │    → MongoDB → DocumentDB, Redis → ElastiCache          │  │
│  │                                                          │  │
│  │  PHASE 3 (12+ tháng):                                   │  │
│  │    → Multi-region deployment                            │  │
│  │    → CDN cho Web UI (CloudFront)                        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Hình ảnh cần có

| Hình | Nguồn | Mô tả |
|------|-------|-------|
| (Optional) Hybrid Architecture Diagram | Tự vẽ | Sơ đồ hybrid on-premise + AWS |
| (Optional) AWS Services Icons | AWS | Lambda, S3, EventBridge, etc. |

---

## Văn nói (Script)

> "Về hướng phát triển tiếp theo, chúng em có kế hoạch migrate hệ thống lên **Hybrid Architecture** - kết hợp on-premise và AWS Cloud.
>
> **Chiến lược phân chia**:
>
> **On-premise** sẽ giữ lại các **Core Services**: Identity, Project Services và các databases chính như PostgreSQL. Điều này đảm bảo dữ liệu nhạy cảm vẫn ở trong hệ thống nội bộ, tuân thủ các quy định về bảo mật và GDPR.
>
> **AWS Cloud** sẽ chạy các **Scalable Services**:
> - **Scraper Services** migrate lên **AWS Lambda** - serverless, pay-per-use, tự động scale theo số lượng crawl jobs
> - **FFmpeg và Playwright** chạy trên **ECS Fargate** cho các tác vụ nặng
> - **Analytics Service** cũng lên Lambda với SQS queue
>
> **Shared Infrastructure**:
> - MinIO → **S3** cho object storage
> - RabbitMQ → **EventBridge + SQS** cho event-driven architecture
> - MongoDB → **DocumentDB**, Redis → **ElastiCache** - managed services
>
> **Lợi ích chính**:
> - **Cost Optimization**: Chỉ trả phí khi scrapers chạy, không phải maintain 24/7
> - **Auto-scaling**: Lambda tự động scale từ 0 đến hàng nghìn instances
> - **Managed Services**: AWS quản lý infrastructure, chúng em tập trung vào business logic
> - **Security & Compliance**: Core data vẫn on-premise
>
> **Timeline**: Chia làm 3 phases trong 12+ tháng, bắt đầu với Scrapers và Storage layer."

---

## Ghi chú kỹ thuật
- Slide này thể hiện tầm nhìn dài hạn
- Nhấn mạnh **Hybrid** thay vì full cloud migration
- Giải thích rõ lý do: Core data on-premise (security), Scalable services on cloud (cost)
- Timeline cụ thể cho thấy feasibility

---

## Key points
1. **Hybrid Architecture**: On-premise (Core) + AWS Cloud (Scalable)
2. **AWS Services**: Lambda (Scrapers, Analytics), S3, EventBridge, SQS, DocumentDB, ElastiCache
3. **Benefits**: Cost optimization, Auto-scaling, Managed services, Security
4. **Timeline**: 3 phases trong 12+ tháng

---

## Câu hỏi có thể gặp

**Q**: Tại sao không migrate toàn bộ lên cloud?
**A**: Core services chứa dữ liệu nhạy cảm về users và projects. Giữ on-premise giúp tuân thủ các quy định bảo mật và GDPR, đồng thời có full control. Các scalable services như scrapers thì phù hợp với cloud vì workload không đều, pay-per-use tiết kiệm chi phí.

**Q**: Chi phí AWS ước tính bao nhiêu?
**A**: Ước tính ~$500-1000/tháng cho phase 1 (Lambda + S3 + EventBridge). Với 1000 videos/ngày, Lambda cost ~$200, S3 ~$100, EventBridge ~$50. So với maintain EC2 instances 24/7 (~$1500/tháng), tiết kiệm ~40-60%.

**Q**: Cold start của Lambda có ảnh hưởng?
**A**: Với crawling tasks, cold start 1-2 giây là chấp nhận được vì mỗi job chạy 10-30 phút. Có thể dùng Provisioned Concurrency cho Analytics Service nếu cần response nhanh.
