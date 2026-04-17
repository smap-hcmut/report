# Note - Section 3.7

## Khác gì so với bản cũ

- Bản cũ viết `Python` được dùng cho `Analytics Service` và `Speech2Text Service`.
- Cách mô tả này đã stale so với current implementation.
- Chưa có câu chốt về chiến lược backend đa ngôn ngữ của SMAP.

## Bản hiện tại đã chỉnh gì

- Thay `Speech2Text Service` bằng `analysis-srv` và `scrapper service` để bám current source.
- Điều chỉnh mô tả `FastAPI` theo hướng phù hợp với service vừa có API layer vừa có worker/runtime bất đồng bộ.
- Thêm câu tổng kết về chiến lược backend đa ngôn ngữ: `Go + Gin` cho control plane/API, `Python + FastAPI` cho analytics pipeline và scrapper runtime.
