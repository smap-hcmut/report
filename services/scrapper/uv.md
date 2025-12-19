# Chuyển đổi từ pyenv + pip sang uv

Dưới đây là lộ trình chi tiết để bạn chuyển đổi "toàn bộ hệ thống" (từ quản lý version Python, quản lý project, đến cài đặt tool) một cách mượt mà nhất.

### Bước 1: Cài đặt `uv`

Đầu tiên, hãy cài `uv`. Bạn không cần gỡ `pyenv` ngay, chúng có thể sống chung, nhưng sau này bạn sẽ thấy không cần `pyenv` nữa.

Chạy lệnh sau trong Terminal (macOS/Linux):

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

*Sau khi cài xong, nhớ restart terminal.*

-----

### Bước 2: Thay thế `pyenv` (Quản lý phiên bản Python)

Trước đây bạn dùng `pyenv install 3.11.0` để cài Python. Giờ đây `uv` sẽ lo việc này nhanh hơn nhiều.

1.  **Cài đặt Python mới qua uv:**
    ```bash
    uv python install 3.12   # Cài bản 3.12 mới nhất
    uv python install 3.10   # Cài bản 3.10
    ```
2.  **Liệt kê các bản đã cài:**
    ```bash
    uv python list
    ```
3.  **Ưu điểm:** `uv` tự động tải và dùng phiên bản Python phù hợp khi bạn chạy project mà không cần phải "kích hoạt" thủ công rườm rà như pyenv.

-----

### Bước 3: Thay thế `pip` trong Project (Migration Guide)

Đây là phần quan trọng nhất. Giả sử bạn đang có một project cũ dùng `requirements.txt`.

#### Quy trình cũ (pyenv + pip):

1.  `pyenv local 3.10`
2.  `python -m venv venv`
3.  `source venv/bin/activate`
4.  `pip install -r requirements.txt`

#### Quy trình mới (uv) - "The Modern Way":

Đi vào thư mục dự án của bạn và làm theo các bước sau:

**1. Khởi tạo uv cho dự án:**

```bash
uv init
```

*Lệnh này sẽ tạo ra file `pyproject.toml` (chuẩn mới thay thế requirements.txt) và file `.python-version`.*

**2. Import thư viện từ `requirements.txt` cũ:**
Thay vì cài thủ công, hãy bảo `uv` đọc file cũ và chuyển sang chuẩn mới:

```bash
uv add -r requirements.txt
```

*Lúc này `uv` sẽ:*

  * Đọc `requirements.txt`.
  * Cài đặt tất cả thư viện cực nhanh.
  * Tự động tạo môi trường ảo `.venv` (bạn không cần gõ lệnh tạo venv nữa).
  * Thêm danh sách thư viện vào `pyproject.toml`.
  * Tạo file `uv.lock` (để khóa version, đảm bảo đồng bộ team).

**3. Chạy code:**
Bạn không cần `source .venv/bin/activate` nữa (dù làm thế vẫn được). Hãy dùng `uv run`:

```bash
uv run app.py
```

`uv run` sẽ tự động tìm môi trường ảo `.venv` và chạy file python trong đó. Nếu môi trường chưa có, nó tự tạo. Nếu thiếu thư viện, nó tự cài.

-----

### Bước 4: Chạy các Script lẻ (Single File Scripts)

Nếu bạn có các file script lẻ (ví dụ: `script.py`) cần thư viện (ví dụ `pandas`) mà không muốn tạo cả một project folder.

**Cách cũ:** Phải tạo venv, pip install pandas, rồi chạy. Rất lười\!

**Cách mới với uv:**
Bạn chỉ cần khai báo dependency ngay trên đầu file `script.py`:

```python
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "pandas",
#     "requests",
# ]
# ///

import pandas as pd
import requests
print("Chạy ngon lành!")
```

Sau đó chạy:

```bash
uv run script.py
```

`uv` sẽ tự tạo một môi trường tạm, cài pandas/requests, chạy xong thì dọn dẹp. Cực kỳ sạch sẽ cho máy tính.

-----

### Bước 5: Thay thế Global Tools (Giống pipx)

Nếu bạn cài các tool như `black`, `ruff`, `ipython`, `jupyter` bằng pip cài global (`pip install black`) hoặc `pipx`.

Hãy dùng `uv tool`:

```bash
uv tool install ruff
uv tool install ipython
```

Nó sẽ cài vào môi trường cách ly, không làm rác hệ thống python chính của bạn, và có thể gọi lệnh `ruff` hay `ipython` ở bất cứ đâu trong terminal.

-----

### Bước 6: Dọn dẹp hệ thống cũ (Optional)

Sau khi quen với `uv`, bạn có thể giải phóng dung lượng đĩa:

1.  **Gỡ các venv cũ:** Xóa thư mục `venv/` hoặc `.venv/` cũ tạo bởi pip trong các project. Chạy `uv sync` để uv tạo lại cái mới (dùng hard-link tiết kiệm dung lượng).
2.  **Gỡ pyenv (nếu muốn):** Khi bạn thấy `uv python` đã đủ tốt.
      * Lưu ý: `uv` tôn trọng file `.python-version` mà `pyenv` tạo ra, nên bạn không cần sửa file config trong các project cũ.

### Tóm tắt các lệnh chuyển đổi (Cheat Sheet)

| Hành động | Lệnh cũ (Pip/Pyenv) | **Lệnh mới (uv)** |
| :--- | :--- | :--- |
| **Cài Python** | `pyenv install 3.12` | `uv python install 3.12` |
| **Tạo venv** | `python -m venv .venv` | `uv venv` (hoặc tự động khi chạy `uv sync`) |
| **Cài thư viện** | `pip install requests` | `uv add requests` |
| **Cài từ file** | `pip install -r requirements.txt` | `uv add -r requirements.txt` |
| **Update thư viện**| `pip install -U requests` | `uv lock --upgrade-package requests` |
| **Chạy app** | `source .venv/bin/activate && python app.py` | `uv run app.py` |
| **Xem list gói** | `pip freeze` | `uv tree` (Trực quan hơn nhiều) |

**Lời khuyên:** Hãy bắt đầu thử nghiệm với một dự án nhỏ trước. Xóa folder `.venv` cũ đi, chạy `uv init` và `uv add -r requirements.txt`. Bạn sẽ thấy tốc độ build lại môi trường nhanh đến mức kinh ngạc.