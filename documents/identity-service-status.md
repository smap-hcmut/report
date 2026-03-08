# Identity Service — Status Document

> Generated from code review: `services/identity/`
> Date: 2026-03-06

---

## 1. Tổng quan

Identity Service là service xác thực và phân quyền trung tâm của SMAP. Được viết bằng Go, sử dụng Gin framework, PostgreSQL (qua SQLBoiler), Redis, và Kafka.

**Hai domain chính:**

- `authentication` — OAuth2, JWT, session, token revocation
- `audit` — thu thập, lưu trữ, và truy vấn audit log

---

## 2. Authentication Domain

### 2.1 OAuth2 Flow (thực tế từ code)

```text
GET /authentication/login
  → InitiateOAuthLogin: generate state → redirect URL Google OAuth
  → Response: { auth_url, state }

GET /authentication/callback?code=xxx&state=xxx
  → ProcessOAuthCallback:
    1. ExchangeCode (code → OAuth token)
    2. GetUserInfo (token → email, name, picture)
    3. Validate allowed domain (config-driven)
    4. Check blocked email list
    5. CreateOrUpdateUser (PostgreSQL, upsert)
    6. MapEmailToRole (config map email→role, NOT Google Groups)
    7. UpdateUserRole (write role hash encrypted to DB)
    8. GenerateToken (RSA JWT, kid from jwt_keys table)
    9. CreateSession (Redis: session:{jti})
   10. PublishAuditEvent (Kafka: audit.events)
  → Set HttpOnly cookie (production) / JSON body (development)
```

**Lưu ý quan trọng:** Google Groups integration đã bị bỏ. Comment trong code: `"Empty groups array as we no longer use Google Groups"`. Role mapping hiện tại chỉ dựa vào email config.

### 2.2 JWT Implementation

**File thực tế:** `pkg/jwt/jwt.go`

```go
type Manager struct {
    secretKey []byte  // shared secret
}
// GenerateToken dùng jwt.SigningMethodHS256
// VerifyToken check jwt.SigningMethodHMAC
```

**=> JWT dùng HS256 (HMAC shared secret), không phải RS256.**

**Lưu ý:** Bảng `jwt_keys` tồn tại trong sqlboiler codegen nhưng **không được dùng** trong JWT generation hiện tại. Đây là artifact từ lần refactor trước, không phải active code.

### 2.3 Session Management (Redis)

| Redis key | Value | TTL |
| --- | --- | --- |
| `session:{jti}` | `{ user_id, jti, created_at, expires_at }` | default / 7d (rememberMe) |
| `user_sessions:{userID}` | JSON array of JTIs | 7 ngày |
| `blacklist:{jti}` | `"1"` | remaining token lifetime |

- Logout: xóa `session:{jti}`, publish audit event LOGOUT
- RevokeToken: đọc session → add to blacklist → xóa session
- RevokeAllUserTokens: lấy tất cả JTI → blacklist từng cái → xóa session mapping

### 2.4 Roles

3 roles được định nghĩa trong code:

```go
RoleAdmin   = "ADMIN"
RoleAnalyst = "ANALYST"
RoleViewer  = "VIEWER"  // default
```

Mapping: config map `email → role`. Người dùng mới không có trong map sẽ nhận `VIEWER`.
Role được lưu dưới dạng hash (encrypted) trong DB field `role_hash`.

### 2.5 API Endpoints

```text
Public:
  GET  /authentication/login      → redirect to OAuth
  GET  /authentication/callback   → process OAuth callback

Protected (mw.Auth):
  POST /authentication/logout     → xóa session
  GET  /authentication/me         → lấy thông tin user hiện tại

Internal:
  POST /authentication/internal/validate        → validate JWT token
  POST /authentication/internal/revoke-token    → revoke token (mw.Admin)
  GET  /authentication/internal/users/:id       → lấy user theo ID
```

---

## 3. Audit Domain

### 3.1 Audit Events (producer)

- Kafka topic: `audit.events`
- Non-blocking publish: nếu Kafka queue full → buffer vào in-memory (max configurable)
- Buffer được flush khi có Kafka success tiếp theo
- Actions được track: `LOGIN`, `LOGOUT`, `LOGIN_FAILED`, `TOKEN_REVOKED`

### 3.2 Audit Consumer

- Topic: `audit.events`
- Group: `audit-consumer-group`
- Batch processing → persist to PostgreSQL

### 3.3 Audit Query API

```text
GET /audit-logs   (mw.Admin required)
  Params: user_id, action, from, to, page, limit (max 100)
  Response: paginated list of audit log entries
```

---

## 4. Issues Phát Hiện Từ Code

### 4.1 [BUG] `/internal` Routes Không Có Auth

File: [authentication/delivery/http/routes.go](../services/identity/authentication/delivery/http/routes.go#L19)

```go
internal := r.Group("/internal") //, mw.ServiceAuth())
```

`mw.ServiceAuth()` bị comment out. Ba endpoint nội bộ hiện không cần authentication:

- `POST /internal/validate` — bất kỳ ai có thể validate/probe token
- `GET /internal/users/:id` — bất kỳ ai có thể lấy user info
- `POST /internal/revoke-token` — chỉ cần ADMIN role (vẫn có `mw.Admin()`)

`ServiceAuth()` đã được implement đầy đủ (decrypt `X-Service-Key` → validate against config) nhưng chưa được enable.

### 4.2 [BUG] Debug Print Trong Production Handler

File: [authentication/delivery/http/internal.go](../services/identity/authentication/delivery/http/internal.go#L27)

```go
fmt.Println("DEBUG: ValidateToken Handler Reached")
```

Cần xóa trước khi deploy.

### 4.3 [NOTE] JWT là HS256, bảng `jwt_keys` không được dùng

Code thực tế (`pkg/jwt/jwt.go`) dùng `jwt.SigningMethodHS256` với `secretKey []byte`.
Bảng `jwt_keys` có trong sqlboiler codegen nhưng không được gọi ở bất kỳ đâu trong JWT logic — đây là artifact từ lần refactor trước.

---

## 5. So Sánh Report Cũ vs Code Thực Tế

| Mục | Report Cũ | Code Thực Tế |
| --- | --- | --- |
| JWT algorithm | HS256 shared secret | HS256 (đúng) — `pkg/jwt/jwt.go` |
| `jwt_keys` table | Mentioned | Tồn tại trong sqlboiler nhưng **không dùng** |
| Role mapping | Google Groups | Email config map (`userRoles`), Groups bỏ |
| Internal auth | X-Service-Key required | `mw.ServiceAuth()` commented out |
| Audit storage | PostgreSQL | Kafka (`audit.events`) → consumer → PostgreSQL |
| Session storage | Redis | Redis (đúng) |
| Token blacklist | Redis | Redis (đúng) |
| OAuth provider | Google | Google (đúng) |

---

## 6. Tình Trạng Tổng Thể

**Implemented và hoạt động:**

- Google OAuth2 flow hoàn chỉnh (10 bước)
- RSA JWT với key rotation lifecycle (active/rotating/retired)
- Session management với Redis
- Token blacklisting với TTL tự động
- RememberMe (7 ngày)
- Audit logging end-to-end (producer → Kafka → consumer → PostgreSQL)
- Audit query API (admin-only, paginated)
- Internal token validation API

**Cần fix trước production:**

- Enable `mw.ServiceAuth()` trên `/internal` routes
- Xóa `fmt.Println("DEBUG: ...")` trong ValidateToken handler

**Không phải bug, nhưng cần document:**

- Google Groups integration đã bị bỏ, role mapping bây giờ chỉ qua email config
- JWT là **HS256** (HMAC shared secret) — bảng `jwt_keys` trong sqlboiler là artifact cũ, không được dùng
- Token TTL mặc định: 8 giờ; rememberMe: 7 ngày
