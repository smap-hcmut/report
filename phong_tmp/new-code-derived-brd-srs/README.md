# Code-Derived BRD + SRS Pack

Bộ tài liệu này được trích xuất từ implementation hiện tại của:
- `project-srv`
- `ingest-srv`
- `identity-srv`
- `test/full_check`

Nguyên tắc:
- Code là nguồn sự thật chính.
- Docs cũ chỉ dùng để đối chiếu drift, không dùng làm nguồn chuẩn.
- Mọi rule đều được phân loại thành `Implemented`, `Partially implemented`, hoặc `Gap`.
- Mọi flow runtime quan trọng đều có `BRD`, `SRS`, `Decision Table`, `Dataflow`, `Evidence`, và `Coverage`.

Thứ tự đọc khuyến nghị:
1. [00-rule-inventory-master.md](/Users/phongdang/Documents/GitHub/SMAP/document/docs/code-derived-brd-srs/00-rule-inventory-master.md)
2. [01-overview.md](/Users/phongdang/Documents/GitHub/SMAP/document/docs/code-derived-brd-srs/01-overview.md)
3. [02-project-domain.md](/Users/phongdang/Documents/GitHub/SMAP/document/docs/code-derived-brd-srs/02-project-domain.md)
4. [03-ingest-datasource-target-domain.md](/Users/phongdang/Documents/GitHub/SMAP/document/docs/code-derived-brd-srs/03-ingest-datasource-target-domain.md)
5. [04-dryrun-execution-scheduler-domain.md](/Users/phongdang/Documents/GitHub/SMAP/document/docs/code-derived-brd-srs/04-dryrun-execution-scheduler-domain.md)
6. [05-identity-boundary-domain.md](/Users/phongdang/Documents/GitHub/SMAP/document/docs/code-derived-brd-srs/05-identity-boundary-domain.md)
7. [06-gap-register.md](/Users/phongdang/Documents/GitHub/SMAP/document/docs/code-derived-brd-srs/06-gap-register.md)

Ghi chú:
- Bộ này tập trung vào business behavior và runtime contract.
- Concern kỹ thuật thuần như logging style, trace implementation detail, hay dependency wiring chỉ được nhắc khi chúng là một runtime contract có thể quan sát được.
- Một số flow có usecase nhưng chưa expose ra HTTP/internal route. Các flow đó vẫn được ghi nhận trong SRS như `code-level capability`, đồng thời đánh dấu coverage gap nếu chưa black-box E2E được.
