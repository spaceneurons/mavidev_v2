#!/usr/bin/env bash
set -euo pipefail
umask 077

site="${MAVIDEV_SITE_ROOT:-$HOME/www/mavidev.pro}"
state="${MAVIDEV_DEPLOY_STATE:-$HOME/.mavidev-deploy}"
remote=https://github.com/spaceneurons/mavidev_v2.git
[[ -d "$site/public" && -d "$site/src" && -d "$site/data" ]]
mkdir -p "$state"
exec 9>"$state/lock"
flock -n 9 || exit 0

if [[ ! -d "$state/repo.git" ]]; then
  git init --bare "$state/repo.git"
fi
git --git-dir="$state/repo.git" fetch --no-tags "$remote" '+refs/heads/main:refs/heads/main'
commit=$(git --git-dir="$state/repo.git" rev-parse refs/heads/main)
if [[ ${1:-} != --check && -f "$state/deployed" && $(cat "$state/deployed") == "$commit" ]]; then
  exit 0
fi

work=$(mktemp -d "$state/stage.XXXXXXXX")
trap 'rm -rf -- "$work"' EXIT
mkdir "$work/release"
git --git-dir="$state/repo.git" archive "$commit" public src | tar -x -C "$work/release"
[[ -f "$work/release/public/index.php" && -f "$work/release/public/admin/index.php" && -f "$work/release/src/bootstrap.php" ]]
if [[ -n $(find "$work/release" -type l -print -quit) ]]; then
  echo "Unexpected symbolic link in release." >&2
  exit 1
fi
while IFS= read -r -d '' file; do
  case "$file" in
    public/uploads/*|*/.*) echo "Excluded deployment path: $file" >&2; exit 1 ;;
    public/admin/*.php|public/admin/*.js|public/admin/*.css|public/api/*.php|public/assets/*.svg|public/assets/*.png|public/assets/*.jpg|public/assets/*.jpeg|public/assets/*.webp|public/assets/*.woff2|public/*.php|public/*.css|public/*.js|public/favicon.svg|src/*.php) ;;
    *) echo "Unexpected release path: $file" >&2; exit 1 ;;
  esac
  if [[ "$file" = *.php ]]; then php -l "$work/release/$file"; fi
done < <(cd "$work/release" && find public src -type f -print0)

if [[ ${1:-} == --check ]]; then
  echo "Validated $commit. No live files changed."
  exit 0
fi

backup="$state/backup-$(date +%Y%m%dT%H%M%S)-${commit:0:12}"
mkdir "$backup"
rsync -rt --chmod=F644,D755 --backup --backup-dir="$backup" "$work/release/" "$site/"
printf '%s\n' "$commit" > "$work/deployed"
mv -f "$work/deployed" "$state/deployed"
echo "Published $commit. Replaced files backed up in $backup."
