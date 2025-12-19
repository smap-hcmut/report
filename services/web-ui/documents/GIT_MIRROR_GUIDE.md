# Git Mirror Guide

Hướng dẫn mirror (sao chép) repository này sang repository khác.

---

## Method 1: Mirror toàn bộ repo (Recommended)

Cách này sẽ copy **toàn bộ history, branches, tags** sang repo mới.

### Bước 1: Tạo bare clone của repo hiện tại

```bash
# Clone repo hiện tại dạng mirror
git clone --mirror <url-repo-hien-tai>

# Ví dụ:
git clone --mirror https://github.com/user/seo-controller.git
cd seo-controller.git
```

### Bước 2: Push lên repo mới

```bash
# Set remote mới
git remote set-url origin <url-repo-moi>

# Ví dụ:
git remote set-url origin https://github.com/newuser/new-seo-controller.git

# Push mirror (toàn bộ branches, tags, refs)
git push --mirror
```

### Bước 3: Cleanup

```bash
# Quay lại thư mục parent
cd ..

# Xóa bare repo
rm -rf seo-controller.git

# Clone repo mới về để làm việc
git clone <url-repo-moi>
cd new-seo-controller
```

---

## Method 2: Push từ repo hiện tại sang repo mới

Nếu bạn đang ở trong repo hiện tại và muốn push sang repo mới:

### Bước 1: Thêm remote mới

```bash
# Xem remote hiện tại
git remote -v

# Thêm remote mới (đặt tên là "new-origin" hoặc bất kỳ tên nào)
git remote add new-origin <url-repo-moi>

# Ví dụ:
git remote add new-origin https://github.com/newuser/new-seo-controller.git
```

### Bước 2: Push toàn bộ lên repo mới

```bash
# Push tất cả branches
git push new-origin --all

# Push tất cả tags
git push new-origin --tags

# Hoặc push mirror (all + tags)
git push new-origin --mirror
```

### Bước 3: (Optional) Đổi origin

Nếu muốn làm việc với repo mới thay vì repo cũ:

```bash
# Đổi tên remote cũ
git remote rename origin old-origin

# Đổi tên remote mới thành origin
git remote rename new-origin origin

# Verify
git remote -v
```

---

## Method 3: Fork và Sync (GitHub/GitLab)

### Trên GitHub:

1. **Fork repo** trên GitHub UI
2. **Clone fork** về máy:
   ```bash
   git clone https://github.com/your-username/forked-repo.git
   cd forked-repo
   ```

3. **Add upstream** (repo gốc):
   ```bash
   git remote add upstream https://github.com/original/repo.git
   ```

4. **Sync changes** từ upstream:
   ```bash
   # Fetch từ upstream
   git fetch upstream

   # Merge vào branch hiện tại
   git merge upstream/main

   # Push lên fork
   git push origin main
   ```

---

## Method 4: Sync thường xuyên giữa 2 repos

Nếu muốn sync thường xuyên giữa repo A và repo B:

### Setup:

```bash
# Add cả 2 remotes
git remote add origin-a <url-repo-a>
git remote add origin-b <url-repo-b>

# Verify
git remote -v
```

### Sync từ A sang B:

```bash
# Fetch từ repo A
git fetch origin-a

# Push sang repo B
git push origin-b main

# Hoặc push tất cả branches
git push origin-b --all
git push origin-b --tags
```

### Tự động sync với script:

Tạo file `sync-repos.sh`:

```bash
#!/bin/bash

echo "Syncing repositories..."

# Fetch từ repo A
git fetch origin-a

# Push sang repo B
git push origin-b --all
git push origin-b --tags

echo "Sync completed!"
```

Chạy:
```bash
chmod +x sync-repos.sh
./sync-repos.sh
```

---

## Method 5: GitHub Actions Auto Sync

Tạo file `.github/workflows/mirror.yml`:

```yaml
name: Mirror Repository

on:
  push:
    branches:
      - main
      - develop

jobs:
  mirror:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - name: Mirror to another repo
        env:
          TARGET_REPO: ${{ secrets.TARGET_REPO_URL }}
          TARGET_TOKEN: ${{ secrets.TARGET_TOKEN }}
        run: |
          git remote add target https://${TARGET_TOKEN}@${TARGET_REPO}
          git push target --mirror
```

Setup secrets trong GitHub:
- `TARGET_REPO_URL`: URL của repo đích (không có https://)
- `TARGET_TOKEN`: Personal access token

---

## Method 6: GitLab CI/CD Mirror

Tạo file `.gitlab-ci.yml`:

```yaml
mirror:
  stage: deploy
  only:
    - main
  script:
    - git remote add mirror $MIRROR_REPO_URL
    - git push mirror --mirror
  variables:
    MIRROR_REPO_URL: "https://oauth2:$MIRROR_TOKEN@github.com/user/repo.git"
```

Setup variables trong GitLab CI/CD:
- `MIRROR_TOKEN`: Personal access token của repo đích

---

## Common Use Cases

### Case 1: Migrate từ GitHub sang GitLab

```bash
# Clone mirror từ GitHub
git clone --mirror https://github.com/user/repo.git
cd repo.git

# Push lên GitLab
git remote set-url origin https://gitlab.com/user/repo.git
git push --mirror

# Verify
cd ..
git clone https://gitlab.com/user/repo.git
```

### Case 2: Backup sang Private Repo

```bash
# Add backup remote
git remote add backup https://github.com/user/private-backup.git

# Push định kỳ
git push backup --all
git push backup --tags
```

### Case 3: Deploy sang nhiều servers

```bash
# Add multiple remotes
git remote add prod-1 https://server1.com/repo.git
git remote add prod-2 https://server2.com/repo.git

# Deploy script
git push prod-1 main
git push prod-2 main
```

---

## Troubleshooting

### Lỗi: Remote already exists

```bash
# Remove remote cũ
git remote remove new-origin

# Add lại
git remote add new-origin <url>
```

### Lỗi: Push rejected

```bash
# Force push (cẩn thận!)
git push --force new-origin main

# Hoặc mirror force
git push --mirror --force
```

### Lỗi: Authentication failed

```bash
# Với HTTPS, dùng personal access token
git remote set-url origin https://<token>@github.com/user/repo.git

# Hoặc dùng SSH
git remote set-url origin git@github.com:user/repo.git
```

### Kiểm tra remotes

```bash
# List tất cả remotes
git remote -v

# Chi tiết remote
git remote show origin

# Test connection
git ls-remote origin
```

---

## Best Practices

### 1. Sử dụng SSH keys thay vì HTTPS

```bash
# Generate SSH key (nếu chưa có)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add key vào ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Add public key vào GitHub/GitLab
cat ~/.ssh/id_ed25519.pub
```

### 2. Protect sensitive data

```bash
# Kiểm tra .gitignore trước khi mirror
cat .gitignore

# Remove sensitive files từ history (nếu cần)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch .env" \
  --prune-empty --tag-name-filter cat -- --all
```

### 3. Verify mirror

```bash
# Clone repo mới
git clone <url-repo-moi> verify-mirror
cd verify-mirror

# Check branches
git branch -a

# Check tags
git tag

# Check history
git log --oneline --graph --all

# Check files
ls -la
```

### 4. Automated sync với cron (Linux/Mac)

```bash
# Edit crontab
crontab -e

# Add sync job (chạy mỗi ngày lúc 2AM)
0 2 * * * cd /path/to/repo && git fetch origin-a && git push origin-b --all && git push origin-b --tags
```

---

## Quick Reference

```bash
# Mirror toàn bộ repo
git clone --mirror <source-url>
cd repo.git
git remote set-url origin <target-url>
git push --mirror

# Push từ repo hiện tại
git remote add new-repo <url>
git push new-repo --all
git push new-repo --tags

# Sync 2 repos
git fetch origin-a
git push origin-b --all --tags

# List remotes
git remote -v

# Remove remote
git remote remove <name>
```

---

## Security Notes

⚠️ **Cảnh báo:**
- Không mirror repo có chứa secrets (.env, credentials)
- Kiểm tra `.gitignore` trước khi mirror
- Sử dụng personal access tokens thay vì passwords
- Revoke tokens khi không dùng nữa
- Private repos cần authentication proper

---

**Happy Mirroring! 🔄**
