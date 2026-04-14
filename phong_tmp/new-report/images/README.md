# Diagram Package

Thư mục này chứa bộ hình chính dùng trong `report/`.

## Files

Moi hinh chinh hien co 2 dinh dang:

- `.svg`: ban render de nhung vao Markdown
- `.excalidraw`: ban editable de mo bang Excalidraw va keo tha truc tiep

- `c4-context-current.svg`: context view của toàn nền tảng
- `c4-container-current.svg`: container view của các service và hạ tầng
- `c4-component-analysis-current.svg`: component view của `analysis-srv`
- `c4-component-knowledge-current.svg`: component view của `knowledge-srv`
- `dynamic-current-dataflow.svg`: luồng dữ liệu hiện tại từ project đến knowledge
- `messaging-topology-current.svg`: sơ đồ cơ chế giao tiếp hiện tại
- `crisis-loop-target.svg`: vòng lặp phản hồi khủng hoảng ở kiến trúc mục tiêu
- `deployment-current-partial.svg`: deployment view ở mức current/partial
- `sequence-project-execution-current.svg`: sequence chính của luồng project execution
- `uml-class-business-domain.svg`: class view cho business domain cốt lõi
- `uml-state-lifecycle-current.svg`: state model cho project lifecycle và business crisis status

## Reading Order

1. `c4-context-current.svg`
2. `c4-container-current.svg`
3. `dynamic-current-dataflow.svg`
4. `messaging-topology-current.svg`
5. `c4-component-analysis-current.svg`
6. `c4-component-knowledge-current.svg`
7. `sequence-project-execution-current.svg`
8. `uml-class-business-domain.svg`
9. `uml-state-lifecycle-current.svg`
10. `deployment-current-partial.svg`
11. `crisis-loop-target.svg`

## Notes

- Các hình `current` phản ánh hiện trạng có bằng chứng mạnh từ source/docs hiện tại.
- `crisis-loop-target.svg` là hình `target / partial`, không nên đọc như runtime fact.
- File giải thích chi tiết từng hình nằm tại `FIGURE_NOTES.md`.
- Neu can chinh sua bang tay, uu tien mo cac file `.excalidraw` trong chinh thu muc nay.
