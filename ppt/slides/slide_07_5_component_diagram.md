# Slide 7.5: Component Diagram - Project Service (C4 Level 3)
**Thời lượng**: 1 phút 30 giây

---

## Nội dung hiển thị

```
COMPONENT DIAGRAM - PROJECT SERVICE (C4 LEVEL 3)
Clean Architecture Implementation

┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │            LAYER 1: PRESENTATION (API/Handlers)          │  │
│  │                                                          │  │
│  │  ┌────────────┐  ┌─────────────┐  ┌────────────────┐   │  │
│  │  │ REST       │  │ Request/    │  │ Middleware     │   │  │
│  │  │ Controllers│  │ Response    │  │ (Auth, RBAC,   │   │  │
│  │  │            │  │ DTOs        │  │  Logging)      │   │  │
│  │  └────────────┘  └─────────────┘  └────────────────┘   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                           ↓                                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │         LAYER 2: APPLICATION (Use Cases)                 │  │
│  │                                                          │  │
│  │  ┌──────────────┐  ┌────────────────┐  ┌────────────┐  │  │
│  │  │ Create       │  │ Execute        │  │ GetProject │  │  │
│  │  │ ProjectUC    │  │ ProjectUC      │  │ DetailsUC  │  │  │
│  │  └──────────────┘  └────────────────┘  └────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                           ↓                                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │          LAYER 3: DOMAIN (Business Logic)                │  │
│  │                                                          │  │
│  │  ┌──────────┐  ┌─────────────┐  ┌─────────────────┐    │  │
│  │  │ Project  │  │ Value       │  │ Domain Events   │    │  │
│  │  │ Entity   │  │ Objects     │  │                 │    │  │
│  │  │          │  │ (Status,    │  │ ProjectCreated  │    │  │
│  │  │ Methods: │  │  Config)    │  │ ExecutionStart  │    │  │
│  │  │ -CanExec │  │             │  │                 │    │  │
│  │  │ -IsActive│  │             │  │                 │    │  │
│  │  └──────────┘  └─────────────┘  └─────────────────┘    │  │
│  │                                                          │  │
│  │  🔒 Business Rules: Không execute project đang chạy    │  │
│  │                     Free plan giới hạn 3 projects      │  │
│  └──────────────────────────────────────────────────────────┘  │
│                           ↓                                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │      LAYER 4: INFRASTRUCTURE (Technical Details)         │  │
│  │                                                          │  │
│  │  ┌────────────┐  ┌─────────────┐  ┌──────────────┐     │  │
│  │  │ PostgreSQL │  │ RabbitMQ    │  │ Redis Cache  │     │  │
│  │  │ Repository │  │ Publisher   │  │              │     │  │
│  │  │ (SQLBoiler)│  │             │  │ TTL: 5 min   │     │  │
│  │  └────────────┘  └─────────────┘  └──────────────┘     │  │
│  │                                                          │  │
│  │  Implements:  IProjectRepository                        │  │
│  │              IEventPublisher                            │  │
│  │              IProjectCache                              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ⚡ DEPENDENCY RULE: Dependencies point INWARD                 │
│     Infrastructure → Domain (via Interfaces)                   │
│     Domain NEVER depends on Infrastructure                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

EXAMPLE FLOW: Execute Project
1. HTTP Request → REST Controller (validate JWT, parse body)
2. Controller → ExecuteProjectUseCase.Execute(projectID, params)
3. UseCase → Load Project entity, call project.CanExecute()
4. Project → Check business rules (status, quota)
5. UseCase → Create ExecutionConfig, publish event via IEventPublisher
6. Infrastructure → Send message to RabbitMQ
7. UseCase → Commit transaction, return response
8. Controller → Serialize to JSON, return HTTP 202 Accepted

BENEFITS:
✅ Testability: Test each layer independently
✅ Maintainability: Change database? Only Infrastructure layer changes
✅ Team Collaboration: Parallel development on different layers
```

---

## Hình ảnh cần có

| Hình | Nguồn | Mô tả |
|------|-------|-------|
| **Component Diagram** | `report/images/component/project-service-component.png` | C4 Level 3 - Component diagram của Project Service |
| (Optional) Clean Architecture Circle | Tự vẽ | Diagram vòng tròn Clean Architecture |

---

## Văn nói (Script)

> "Để thấy rõ hơn cách chúng em tổ chức code bên trong mỗi service, nhóm xin phép đi sâu vào **Component Diagram** của **Project Service** - một ví dụ điển hình cho việc áp dụng **Clean Architecture**.
>
> Theo mô hình C4 Level 3, Project Service được chia thành **4 layers** rõ ràng từ ngoài vào trong:
>
> **Layer 1 - Presentation**: Tiếp nhận HTTP requests, REST Controllers, Request/Response DTOs, Middleware chain (Auth, RBAC, Logging). Tầng này **không chứa business logic**.
>
> **Layer 2 - Application (Use Cases)**: Orchestrate business workflows - CreateProjectUseCase, ExecuteProjectUseCase, GetProjectDetailsUseCase. Use Cases chỉ biết về Domain Models và Repository Interfaces.
>
> **Layer 3 - Domain**: Trái tim của service - Project Entity với business methods, Value Objects, Domain Events, Business Rules. Domain layer **hoàn toàn độc lập** với frameworks.
>
> **Layer 4 - Infrastructure**: Technical details - PostgreSQL Repository (SQLBoiler ORM), RabbitMQ Publisher, Redis Cache. Implements các interfaces được định nghĩa bởi Domain.
>
> **Dependency Rule** quan trọng nhất: Mũi tên dependencies luôn chỉ **từ ngoài vào trong**. Infrastructure phụ thuộc vào Domain, nhưng Domain **không biết gì** về Infrastructure. Đạt được nhờ **Dependency Inversion Principle**.
>
> Ví dụ luồng Execute Project:
> 1. HTTP Request → Controller validate JWT
> 2. Controller → ExecuteProjectUseCase
> 3. UseCase → Project entity kiểm tra business rules
> 4. UseCase → Publish event qua RabbitMQ
> 5. Return HTTP 202 Accepted
>
> Clean Architecture này mang lại **3 lợi ích**:
> - **Testability**: Test từng layer độc lập
> - **Maintainability**: Thay database? Chỉ sửa Infrastructure layer
> - **Team Collaboration**: Dev làm song song các layers khác nhau
>
> Đây là minh chứng chúng em không chỉ 'code chạy được' mà còn **'code theo chuẩn mực công nghiệp'**."

---

## Ghi chú kỹ thuật

- Đây là slide **QUAN TRỌNG** để show off kỹ năng software architecture
- Nhấn mạnh **Clean Architecture** và **Dependency Inversion Principle**
- Sử dụng thuật ngữ chuẩn: Presentation, Application, Domain, Infrastructure
- Giải thích rõ **Dependency Rule** (dependencies point inward)
- Đưa ví dụ cụ thể (Execute Project flow) để dễ hiểu

---

## Key points

1. **4 Layers**: Presentation → Application → Domain → Infrastructure
2. **Clean Architecture**: Dependency Rule (inward dependencies)
3. **Domain-Driven Design**: Entities, Value Objects, Domain Events
4. **Dependency Inversion**: Domain defines interfaces, Infrastructure implements
5. **Benefits**: Testability, Maintainability, Team Collaboration
6. **Golang Best Practices**: Interface segregation, SQLBoiler ORM

---

## Câu hỏi có thể gặp

**Q**: Tại sao không dùng GORM thay vì SQLBoiler?
**A**: "SQLBoiler là code generator, tạo ra type-safe code từ database schema. GORM là reflection-based ORM, slower và less type-safe. Với SQLBoiler:
- Compile-time safety: Lỗi database được phát hiện lúc compile
- Performance: Không có reflection overhead, nhanh hơn GORM ~30-50%
- Code completion: IDE autocomplete tất cả columns và methods
- Migration-first workflow: Schema là source of truth

Trade-off là phải regenerate code sau mỗi migration, nhưng benefits về type safety và performance xứng đáng."

**Q**: Domain layer test như thế nào mà không có database?
**A**: "Domain layer chỉ chứa pure business logic, không có database dependencies. Test example:

```go
func TestProjectCanExecute(t *testing.T) {
    project := &Project{
        Status: StatusActive,
        LastExecutedAt: time.Now().Add(-2 * time.Hour),
    }

    canExecute := project.CanExecute()

    assert.True(t, canExecute)
}
```

Không cần mock database, không cần setup containers. Pure unit test chạy <1ms, coverage >90%."

**Q**: Repository pattern có thừa không khi đã có ORM?
**A**: "Repository pattern không thừa, mà là abstraction layer quan trọng:
- **Decoupling**: Domain không biết về SQLBoiler. Ngày mai muốn đổi sang Ent ORM? Chỉ sửa Infrastructure layer.
- **Testing**: Use Case test với mock repository, không cần real database.
- **Business queries**: Repository expose methods như `FindActiveProjects()`, `FindByUserAndStatus()` thay vì raw SQL.
- **Transaction management**: Repository handle transaction scope, Use Case không cần biết.

Đây là pattern trong Clean Architecture và Domain-Driven Design, không phải over-engineering."

**Q**: 4 layers có quá phức tạp cho một service nhỏ không?
**A**: "Với project nhỏ (1-2 devs, <10 endpoints), có thể thừa. Nhưng SMAP có:
- 10 services, 5-7 devs
- 47 Functional Requirements, 31 Non-Functional Requirements
- Plan scale lên production với hàng triệu records

Với quy mô này, Clean Architecture là **necessary**, không phải nice-to-have. Benefits về maintainability, testability, và team collaboration vượt xa initial complexity.

Hơn nữa, đây là đồ án tốt nghiệp - cơ hội để demonstrate hiểu biết về industry-standard architecture patterns. Đây là điểm mạnh để được điểm cao và impress hội đồng."

---

## Transition

> "Vậy là chúng em đã đi sâu vào internal structure của một service Golang. Tiếp theo, nhóm xin trình bày về infrastructure components để vận hành cả hệ thống..."

---

**End of Slide 7.5 Script**
