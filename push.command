#!/bin/bash
# bubble 一鍵推送（需先建 Public 倉庫 stata_bubble，並設好 Keychain 認證）
cd "$(dirname "$0")" || exit 1
rm -f .git/index.lock .git/HEAD.lock 2>/dev/null
if [ ! -d .git ]; then git init >/dev/null; git branch -M main; fi
git config user.email "jay8956047@gmail.com"
git config user.name "Wen-Cheng Lin"
if git remote | grep -q origin; then
  git remote set-url origin "https://github.com/ganma0517/stata_bubble.git"
else
  git remote add origin "https://github.com/ganma0517/stata_bubble.git"
fi
git add -A
git commit -m "update bubble" || echo "（無新變更）"
git push -u origin main
read -n 1 -s -r -p "按任意鍵關閉視窗..."
