// Import counter dùng chung
#import "../counters.typ": table_counter, image_counter

== 5.4 Sơ đồ cơ sở dữ liệu (Database Schema)

=== Tổng quan kiến trúc Database

Hệ thống SMAP sử dụng kiến trúc microservices với 2 database PostgreSQL độc lập:
- *Identity Service Database*: Quản lý users, plans, subscriptions
- *Project Service Database*: Quản lý projects

Việc tách biệt database cho phép scaling độc lập giữa các services và tuân thủ nguyên tắc microservices. Mối quan hệ giữa users và projects được validate thông qua JWT token ở application layer thay vì Foreign Key constraint.

=== Schema Identity Service

// #image("../images/schema/identity-schema.png")
#context (align(center)[_Hình #image_counter.display(): Schema Identity Service_])
#image_counter.step()

Schema Identity Service bao gồm 3 tables chính: *users* (lưu thông tin người dùng với xác thực, phân quyền, OTP), *plans* (định nghĩa các gói dịch vụ subscription với max_usage giới hạn số projects), và *subscriptions* (quản lý subscription của users với plans, bao gồm status enum: active, trialing, past_due, cancelled, expired). Mối quan hệ: users ← subscriptions → plans (many-to-many qua subscriptions). Tất cả tables implement soft delete pattern với field deleted_at.

=== Schema Project Service

#image("../images/schema/SMAP-collector.png")
#context (align(center)[_Hình #image_counter.display(): Schema Project Service_])
#image_counter.step()

Schema Project Service bao gồm table *projects* lưu trữ thông tin dự án theo dõi thương hiệu với các fields chính: id (UUID), name, description, status (draft/active/completed/archived/cancelled), from_date/to_date (khoảng thời gian theo dõi), brand_name, competitor_names (TEXT[]), brand_keywords (TEXT[]), competitor_keywords_map (JSONB chứa map từ khóa của từng đối thủ), exclude_keywords (TEXT[]), và created_by (UUID của user, không có FK vì ở database khác). Indexes được tạo trên created_by, status và deleted_at để tối ưu query performance.

=== Mối quan hệ Cross-Database

Mối quan hệ giữa projects.created_by và users.id là logical relationship (không có FK constraint) do nằm ở 2 databases khác nhau. Việc validate user_id được thực hiện ở application layer thông qua JWT token, cho phép:
- Scaling độc lập giữa Identity và Project services
- Deploy và maintain riêng biệt từng service
- Tránh distributed transaction complexity

=== Data Types và Constraints

Hệ thống sử dụng các PostgreSQL-specific types:
- *UUID*: Sử dụng extension uuid-ossp với gen_random_uuid()
- *TIMESTAMPTZ*: Timestamp with timezone cho tất cả time fields
- *TEXT[]*: PostgreSQL array type cho danh sách strings
- *JSONB*: Binary JSON format cho competitor_keywords_map (flexible data)
- *ENUM*: Custom enum type cho subscription_status

Tất cả tables có indexes phù hợp và implement soft delete pattern (deleted_at) để hỗ trợ audit trail, recovery và historical data analysis.
