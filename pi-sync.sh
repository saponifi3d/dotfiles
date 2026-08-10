#!/usr/bin/env bash
#
# pi-sync.sh (v4) — copy your live pi config INTO your dotfiles repo,
#                   following symlinks so real content lands in git.
#
#   export DOTFILES=~/code/dotfiles
#   ./pi-sync.sh                # sync live config -> repo
#   ./pi-sync.sh --dry-run      # show what would change
#   ./pi-sync.sh --commit       # ...and git commit if the audit passes
#   ./pi-sync.sh --heal         # clear dangling symlinks in ~/.pi/agent
#   ./pi-sync.sh --prune        # delete repo entries no longer present live
#
# DESIGN
#   ~/.pi/agent is the SOURCE OF TRUTH and is only ever READ.
#   Everything is copied into $DOTFILES/configs/pi, which git tracks.
#   Nothing outside $DOTFILES is created, moved, renamed or modified
#   (the sole exception is --heal, which deletes dangling symlinks).
#
# v4 fixes the two reasons nothing reached the repo:
#   * `cp -R` on macOS COPIES A SYMLINK AS A SYMLINK. Extensions you had
#     linked to ~/src/pi therefore arrived in the repo as links pointing
#     outside it — dangling on any other machine. v4 uses `cp -RL` and
#     `cp -L` so the real file content is written into git.
#   * If ~/.pi/agent/extensions was ITSELF a symlink aimed into the repo,
#     v3 reported "already in repo" and skipped it, even when the repo
#     directory did not exist. v4 only treats that as a no-op when the
#     resolved target genuinely exists.
#
# Every entry is reported individually, and the run fails loudly if
# nothing ended up in the repo.

set -euo pipefail

DRY=0; DO_COMMIT=0; HEAL=0; PRUNE=0
for a in "${@:-}"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --commit)  DO_COMMIT=1 ;;
    --heal)    HEAL=1 ;;
    --prune)   PRUNE=1 ;;
    "") ;;
    *) echo "unknown flag: $a" >&2; exit 2 ;;
  esac
done

: "${DOTFILES:?export DOTFILES=~/code/dotfiles first}"
AGENT="$HOME/.pi/agent"
PI_CONFIG="$DOTFILES/configs/pi"
REPO_EXT="$PI_CONFIG/extensions"
MAKEFILE="$DOTFILES/Makefile"
STAMP="$(date +%Y%m%d-%H%M%S)"

FILE_ITEMS=(settings.json keybindings.json AGENTS.md SYSTEM.md)
DIR_ITEMS=(themes extensions prompts skills)
SECRETS=(auth.json trust.json sessions npm git)
PI_SHA="ac4ac9eaf69f2b01ca3af984a5c48f3b99b84278"

BEGIN_MARK="# >>> pi coding agent — managed by pi-sync.sh, edits will be overwritten"
END_MARK="# <<< pi coding agent"

COPIED=0; DANGLING=0

say()   { printf '%s\n' "$*"; }
head1() { printf '\n\033[1m%s\033[0m\n' "$*"; }
run()   { if [ "$DRY" -eq 1 ]; then say "      would: $*"; else eval "$@"; fi; }
rp()    { python3 -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' "$1"; }
inrepo(){ case "$1" in "$DF_REAL"/*) return 0 ;; *) return 1 ;; esac; }

# --- 0. preflight ----------------------------------------------------------
head1 "0. Preflight"
[ -d "$AGENT" ]         || { echo "FAIL: $AGENT missing. Is pi installed?" >&2; exit 1; }
[ -d "$DOTFILES/.git" ] || { echo "FAIL: $DOTFILES is not a git repo." >&2; exit 1; }
command -v python3 >/dev/null || { echo "FAIL: python3 required." >&2; exit 1; }
DF_REAL="$(rp "$DOTFILES")"
say "    source (read-only) : $AGENT"
say "    dest   (tracked)   : $PI_CONFIG"
if [ "$DRY" -eq 1 ]; then printf '    mode               : \033[1;33mDRY RUN\033[0m\n'
else printf '    mode               : \033[1;32mAPPLY\033[0m\n'; fi

# --- 1. inventory (symlink-aware) ------------------------------------------
head1 "1. Live config inventory (symlinks resolved)"
describe () {                      # $1 = path -> prints "TYPE|NOTE"
  local p="$1" t
  if [ -L "$p" ]; then
    t="$(rp "$p")"
    if [ ! -e "$t" ]; then printf 'DANGLING|-> %s' "$t"
    elif inrepo "$t";     then printf 'link|-> repo: %s' "${t#$DF_REAL/}"
    elif [ -d "$t" ];     then printf 'link->dir|-> %s' "$t"
    else                       printf 'link->file|-> %s' "$t"; fi
  elif [ -d "$p" ]; then printf 'dir|%s file(s)' "$(find -L "$p" -type f 2>/dev/null | wc -l | tr -d ' ')"
  elif [ -f "$p" ]; then printf 'file|%s bytes' "$(wc -c <"$p" | tr -d ' ')"
  else printf '%s' '-|'; fi
}

for i in "${FILE_ITEMS[@]}" "${DIR_ITEMS[@]}"; do
  IFS='|' read -r t note <<<"$(describe "$AGENT/$i")"
  printf '    %-17s %-11s %s\n' "$i" "$t" "$note"
  [ "$t" = "DANGLING" ] && DANGLING=$((DANGLING+1))
done

# the extensions dir is the crux — enumerate it entry by entry
if [ -e "$AGENT/extensions" ]; then
  say ""
  say "    extensions/ contents:"
  EXT_SRC="$AGENT/extensions"
  [ -L "$EXT_SRC" ] && EXT_SRC="$(rp "$EXT_SRC")"
  if [ -d "$EXT_SRC" ]; then
    shopt -s nullglob
    for e in "$EXT_SRC"/*; do
      IFS='|' read -r t note <<<"$(describe "$e")"
      printf '      %-24s %-11s %s\n' "$(basename "$e")" "$t" "$note"
      [ "$t" = "DANGLING" ] && DANGLING=$((DANGLING+1))
    done
    shopt -u nullglob
  else
    say "      (unreadable: $EXT_SRC)"
  fi
fi

if [ "$DANGLING" -gt 0 ]; then
  say ""
  say "    $DANGLING dangling symlink(s). Their targets no longer exist, so"
  say "    there is nothing to copy from them."
  if [ "$HEAL" -eq 1 ] && [ "$DRY" -eq 0 ]; then
    for i in "${FILE_ITEMS[@]}" "${DIR_ITEMS[@]}"; do
      p="$AGENT/$i"; [ -L "$p" ] && [ ! -e "$p" ] && { rm -f "$p"; say "    healed  $i"; }
    done
    if [ -d "$AGENT/extensions" ] && [ ! -L "$AGENT/extensions" ]; then
      shopt -s nullglob
      for e in "$AGENT/extensions"/*; do
        [ -L "$e" ] && [ ! -e "$e" ] && { rm -f "$e"; say "    healed  extensions/$(basename "$e")"; }
      done
      shopt -u nullglob
    fi
  else
    say "    Re-run with --heal to remove them."
  fi
fi

# --- 2. sync live -> repo, dereferencing symlinks --------------------------
head1 "2. Sync into the repo (following symlinks)"
run "mkdir -p '$PI_CONFIG'"

for i in "${FILE_ITEMS[@]}"; do
  src="$AGENT/$i"; dst="$PI_CONFIG/$i"
  if [ -L "$src" ] && [ ! -e "$src" ]; then say "    dangling $i — nothing to copy"; continue; fi
  if [ ! -e "$src" ]; then
    [ -e "$dst" ] && say "    keep    $i (repo only)" || say "    -       $i"
    continue
  fi
  resolved="$(rp "$src")"
  if inrepo "$resolved" && [ -e "$resolved" ]; then
    say "    ok      $i (live already points at the repo copy)"; continue
  fi
  if [ -e "$dst" ] && cmp -s "$src" "$dst"; then say "    same    $i"; continue; fi
  run "cp -pL '$src' '$dst'"          # -L: write content, never a link
  say "    copied  $i"
  COPIED=$((COPIED+1))
done

for i in "${DIR_ITEMS[@]}"; do
  src="$AGENT/$i"; dst="$PI_CONFIG/$i"

  if [ -L "$src" ]; then
    resolved="$(rp "$src")"
    if [ ! -e "$resolved" ]; then
      say "    dangling $i/ -> $resolved"
      inrepo "$resolved" && {
        say "             (points into the repo, which is empty — leftover from"
        say "              pi-sync v1/v2; see the note at the end)"; }
      continue
    fi
    if inrepo "$resolved"; then
      say "    ok      $i/ (live already points at the repo copy)"; continue
    fi
    say "    follow  $i/ -> $resolved"
    src="$resolved"
  fi

  if [ ! -d "$src" ]; then
    [ -d "$dst" ] && say "    keep    $i/ (repo only)" || say "    -       $i/"
    continue
  fi

  shopt -s nullglob
  entries=("$src"/*)
  shopt -u nullglob
  if [ "${#entries[@]}" -eq 0 ]; then say "    empty   $i/"; continue; fi
  [ "${#entries[@]}" -gt 25 ] && say "    NOTE    $i/ has ${#entries[@]} entries — did you link a whole upstream dir?"

  run "mkdir -p '$dst'"
  for entry in "${entries[@]}"; do
    base="$(basename "$entry")"
    if [ -L "$entry" ] && [ ! -e "$entry" ]; then
      say "      dangling $i/$base"; continue
    fi
    run "rm -rf '$dst/$base'"
    run "cp -RL '$entry' '$dst/$base'"   # -L: dereference into real content
    if [ -L "$entry" ]; then say "      deref    $i/$base"
    else say "      copied   $i/$base"; fi
    COPIED=$((COPIED+1))
  done

  if [ "$PRUNE" -eq 1 ] && [ -d "$dst" ]; then
    shopt -s nullglob
    for entry in "$dst"/*; do
      base="$(basename "$entry")"
      [ -e "$src/$base" ] || { run "rm -rf '$entry'"; say "      pruned   $i/$base"; }
    done
    shopt -u nullglob
  fi
done

say ""
say "    $COPIED item(s) written into the repo"

# --- 3. vendor extensions referenced by absolute path ----------------------
head1 "3. Extensions referenced from settings.json"
LIVE_SETTINGS="$AGENT/settings.json"
if [ ! -e "$LIVE_SETTINGS" ]; then
  say "    no readable live settings.json — skipping"
else
  DRY="$DRY" SETTINGS="$LIVE_SETTINGS" REPO_EXT="$REPO_EXT" DF_REAL="$DF_REAL" python3 <<'PY'
import json, os, re, shutil, sys
dry, sp = os.environ["DRY"] == "1", os.environ["SETTINGS"]
repo_ext, df = os.environ["REPO_EXT"], os.environ["DF_REAL"]

def strip_jsonc(s):
    out, i, n, instr, esc = [], 0, len(s), False, False
    while i < n:
        c = s[i]
        if instr:
            out.append(c)
            if esc: esc = False
            elif c == "\\": esc = True
            elif c == '"': instr = False
            i += 1; continue
        if c == '"': instr = True; out.append(c); i += 1; continue
        if c == "/" and i+1 < n and s[i+1] == "/":
            while i < n and s[i] != "\n": i += 1
            continue
        if c == "/" and i+1 < n and s[i+1] == "*":
            i += 2
            while i+1 < n and not (s[i] == "*" and s[i+1] == "/"): i += 1
            i += 2; continue
        out.append(c); i += 1
    return "".join(out)

def parse(t): return json.loads(re.sub(r",(\s*[}\]])", r"\1", strip_jsonc(t)))

try:
    data = parse(open(sp).read())
except Exception as e:
    print(f"    WARN: live settings.json unreadable ({e})", file=sys.stderr); sys.exit(0)

entries = data.get("extensions") or []
if not isinstance(entries, list): entries = []
if not entries:
    print('    no "extensions" array'); sys.exit(0)

if not dry: os.makedirs(repo_ext, exist_ok=True)
for e in entries:
    p = os.path.realpath(os.path.expanduser(os.path.expandvars(e)))
    base = os.path.basename(p)
    if not os.path.exists(p): print(f"    MISSING  {e}"); continue
    if p.startswith(df):     print(f"    in-repo  {base}"); continue
    print(f"    vendor   {base}")
    if dry: continue
    dest = os.path.join(repo_ext, base)
    if os.path.isdir(p):
        shutil.rmtree(dest, ignore_errors=True)
        shutil.copytree(p, dest, symlinks=False)   # dereference
    else:
        shutil.copy2(os.path.realpath(p), dest)
PY
fi

# --- 4. portability fix on the REPO COPY only -----------------------------
head1 "4. Portability fix (repo copy only — live file untouched)"
if [ ! -e "$PI_CONFIG/settings.json" ]; then
  say "    no repo settings.json yet"
elif [ "$DRY" -eq 1 ]; then
  say "    would strip any \"extensions\" array from the repo copy"
else
  SETTINGS="$PI_CONFIG/settings.json" python3 <<'PY'
import json, os, re, sys
sp = os.environ["SETTINGS"]; raw = open(sp).read()
def strip_jsonc(s):
    out, i, n, instr, esc = [], 0, len(s), False, False
    while i < n:
        c = s[i]
        if instr:
            out.append(c)
            if esc: esc = False
            elif c == "\\": esc = True
            elif c == '"': instr = False
            i += 1; continue
        if c == '"': instr = True; out.append(c); i += 1; continue
        if c == "/" and i+1 < n and s[i+1] == "/":
            while i < n and s[i] != "\n": i += 1
            continue
        if c == "/" and i+1 < n and s[i+1] == "*":
            i += 2
            while i+1 < n and not (s[i] == "*" and s[i+1] == "/"): i += 1
            i += 2; continue
        out.append(c); i += 1
    return "".join(out)
def parse(t): return json.loads(re.sub(r",(\s*[}\]])", r"\1", strip_jsonc(t)))
try: data = parse(raw)
except Exception as e:
    print(f"    WARN: repo settings.json unreadable ({e})", file=sys.stderr); sys.exit(0)
if not data.get("extensions"):
    print('    already portable'); sys.exit(0)
lines = raw.splitlines(keepends=True)
start = next((i for i,l in enumerate(lines) if re.search(r'"extensions"\s*:', l)), None)
if start is None: print("    WARN: key not found", file=sys.stderr); sys.exit(0)
depth, end = 0, None
for i in range(start, len(lines)):
    depth += lines[i].count("[") - lines[i].count("]")
    if depth <= 0 and "]" in lines[i]: end = i; break
if end is None: print("    WARN: unbalanced array", file=sys.stderr); sys.exit(0)
del lines[start:end+1]
for j in range(len(lines)-1, -1, -1):
    s = lines[j].strip()
    if not s or s in ("}", "},"): continue
    if s.endswith(","): lines[j] = lines[j].rstrip()[:-1] + "\n"
    break
new = "".join(lines); parse(new); open(sp, "w").write(new)
print('    stripped "extensions" array from the repo copy (parse verified)')
PY
fi

# --- 5. Makefile ----------------------------------------------------------
head1 "5. Makefile"
BLOCK_TMP="$(mktemp)"
sed 's/@T@/\t/g' > "$BLOCK_TMP" <<BLOCK
$BEGIN_MARK
PI_SHA := $PI_SHA
PI_EXAMPLES := git-checkpoint todo permission-gate protected-paths notify \\
               status-line confirm-destructive dirty-repo-guard
PI_CONFIG := \$(DOTFILES)/configs/pi
PI_AGENT  := \$(HOME)/.pi/agent

.PHONY: pi # Install the pi coding agent and link its configuration
pi: pi_check
@T@npm install -g --ignore-scripts @earendil-works/pi-coding-agent || make msg
@T@mkdir -p \$(PI_AGENT)
@T@ln -s \$(PI_CONFIG)/settings.json \$(PI_AGENT)/settings.json || make msg
@T@ln -s \$(PI_CONFIG)/keybindings.json \$(PI_AGENT)/keybindings.json || make msg
@T@ln -s \$(PI_CONFIG)/AGENTS.md \$(PI_AGENT)/AGENTS.md || make msg
@T@ln -s \$(PI_CONFIG)/themes \$(PI_AGENT)/themes || make msg
@T@ln -s \$(PI_CONFIG)/extensions \$(PI_AGENT)/extensions || make msg
@T@ln -s \$(PI_CONFIG)/prompts \$(PI_AGENT)/prompts || make msg
@T@@echo
@T@@echo "Linked what was missing. Existing files were left alone."
@T@@echo "Verify with: pi config"

.PHONY: pi_check # Verify configs/pi is self-contained and portable
pi_check:
@T@@test -d "\$(PI_CONFIG)/extensions" || { \\
@T@  echo "FAIL: \$(PI_CONFIG)/extensions missing. Run pi-sync.sh (or make pi_vendor)."; exit 1; }
@T@@n=\`find "\$(PI_CONFIG)/extensions" -maxdepth 1 -name '*.ts' | wc -l | tr -d ' '\`; \\
@T@ d=\`find "\$(PI_CONFIG)/extensions" -maxdepth 2 -name 'index.ts' | wc -l | tr -d ' '\`; \\
@T@ t=\`expr \$\$n + \$\$d\`; echo "loadable extensions committed: \$\$t"; \\
@T@ if [ "\$\$t" -eq 0 ]; then \\
@T@   echo "FAIL: no extensions in the repo. pi would load nothing."; exit 1; fi
@T@@l=\`find "\$(PI_CONFIG)" -type l | wc -l | tr -d ' '\`; \\
@T@ if [ "\$\$l" -ne 0 ]; then \\
@T@   echo "FAIL: \$\$l symlink(s) inside configs/pi — these break on a new machine:"; \\
@T@   find "\$(PI_CONFIG)" -type l; exit 1; fi
@T@@if grep -rq -E '(/Users/|/home/|~/src/)' "\$(PI_CONFIG)" --include='*.json' 2>/dev/null; then \\
@T@   echo "FAIL: machine-specific paths in configs/pi:"; \\
@T@   grep -rn -E '(/Users/|/home/|~/src/)' "\$(PI_CONFIG)" --include='*.json'; exit 1; fi
@T@@echo "configs/pi is self-contained."

.PHONY: pi_vendor # Re-vendor pi's upstream example extensions at PI_SHA
pi_vendor:
@T@rm -rf /tmp/pi-vendor
@T@git clone --filter=blob:none --sparse https://github.com/earendil-works/pi.git /tmp/pi-vendor
@T@cd /tmp/pi-vendor && git sparse-checkout set packages/coding-agent/examples/extensions && git checkout \$(PI_SHA)
@T@mkdir -p \$(PI_CONFIG)/extensions
@T@for f in \$(PI_EXAMPLES); do \\
@T@  cp /tmp/pi-vendor/packages/coding-agent/examples/extensions/\$\$f.ts \$(PI_CONFIG)/extensions/; done
@T@rm -rf \$(PI_CONFIG)/extensions/subagent
@T@cp -R /tmp/pi-vendor/packages/coding-agent/examples/extensions/subagent \$(PI_CONFIG)/extensions/
@T@rm -rf /tmp/pi-vendor
@T@@echo "Vendored at \$(PI_SHA)."

.PHONY: pi_unlink # Remove pi symlinks, leaving real files, sessions and auth intact
pi_unlink:
@T@for f in settings.json keybindings.json AGENTS.md themes extensions prompts; do \\
@T@  if [ -L "\$(PI_AGENT)/\$\$f" ]; then rm -f "\$(PI_AGENT)/\$\$f"; echo "unlinked \$\$f"; fi; done
@T@@echo "Only symlinks were removed. Real files, auth.json and sessions/ untouched."
$END_MARK
BLOCK

if [ ! -f "$MAKEFILE" ]; then
  say "    WARN: no Makefile at $MAKEFILE — skipping"
elif [ "$DRY" -eq 1 ]; then
  grep -qF "$BEGIN_MARK" "$MAKEFILE" \
    && say "    would refresh the managed pi block" \
    || say "    would append the managed pi block (removing legacy pi rules)"
else
  cp "$MAKEFILE" "$MAKEFILE.bak-$STAMP"
  python3 - "$MAKEFILE" "$BLOCK_TMP" "$BEGIN_MARK" "$END_MARK" <<'PY'
import re, sys
mk, blockfile, begin, end = sys.argv[1:5]
src = open(mk).read(); block = open(blockfile).read().rstrip("\n") + "\n"
if begin in src and end in src:
    src = src.split(begin)[0] + src.split(end, 1)[1]
PI_TARGETS = {"pi", "pi_check", "pi_vendor", "pi_unlink"}
lines = src.splitlines(keepends=True); keep, i, n, removed = [], 0, len(lines), 0
while i < n:
    l = lines[i]
    is_assign = bool(re.match(r'^PI_[A-Z_]+\s*:?=', l))
    mp = re.match(r'^\.PHONY:\s*([A-Za-z0-9_.-]+)', l)
    mt = re.match(r'^([A-Za-z0-9_.-]+)\s*:', l)
    is_phony  = bool(mp and mp.group(1) in PI_TARGETS)
    is_target = bool(mt and mt.group(1) in PI_TARGETS)
    if is_assign or is_phony or is_target:
        while i < n:
            cur = lines[i]; i += 1; removed += 1
            if not cur.rstrip("\n").endswith("\\"): break
        if is_target:
            while i < n and lines[i].startswith("\t"): i += 1; removed += 1
        continue
    keep.append(l); i += 1
src = re.sub(r"\n{3,}", "\n\n", "".join(keep))
print(f"    removed {removed} legacy pi line(s)" if removed else "    no legacy pi rules found")
if not src.endswith("\n"): src += "\n"
src += "\n" + block
print("    wrote the managed pi block")
state = {"added": False}
def add_pi(m):
    deps = m.group(1).rstrip()
    if re.search(r'(^|\s)pi(\s|$)', deps): return m.group(0)
    state["added"] = True; return f"install:{deps} pi"
src, n_sub = re.subn(r'^install:([^\n]*)$', add_pi, src, count=1, flags=re.M)
print("    added pi to install:" if state["added"]
      else ("    install: already lists pi" if n_sub else "    WARN: no install: target"))
open(mk, "w").write(src)
final = open(mk).read()
for t in sorted(PI_TARGETS):
    c = len(re.findall(rf'^{t}\s*:', final, flags=re.M))
    if c != 1: print(f"    WARN: `{t}` defined {c} time(s)", file=sys.stderr)
PY
  say "    backup: $(basename "$MAKEFILE.bak-$STAMP")"
fi
rm -f "$BLOCK_TMP"

# --- 6. gitignore ---------------------------------------------------------
head1 "6. .gitignore"
GI="$DOTFILES/.gitignore"; need=0
for s in "${SECRETS[@]}"; do grep -qF "configs/pi/$s" "$GI" 2>/dev/null || need=1; done
grep -qF 'Makefile.bak-' "$GI" 2>/dev/null || need=1
if [ "$need" -eq 0 ]; then say "    already guarded"
elif [ "$DRY" -eq 1 ]; then say "    would add secret guards"
else
  { printf '\n# pi — runtime state, never commit\n'
    for s in "${SECRETS[@]}"; do printf 'configs/pi/%s\n' "$s"; done
    printf 'Makefile.bak-*\n'; } >> "$GI"
  say "    added secret guards"
fi

# --- 7. audit ------------------------------------------------------------
head1 "7. Audit"
FAIL=0
for s in "${SECRETS[@]}"; do
  [ -e "$PI_CONFIG/$s" ] && { say "    SECRET LEAK: configs/pi/$s"; FAIL=1; }
done
[ "$FAIL" -eq 0 ] && say "    secrets   clean"

NLINK=$(find "$PI_CONFIG" -type l 2>/dev/null | wc -l | tr -d ' ')
if [ "$NLINK" -ne 0 ]; then
  say "    SYMLINKS  $NLINK symlink(s) inside configs/pi — would dangle elsewhere:"
  find "$PI_CONFIG" -type l 2>/dev/null | sed "s|$DOTFILES/|              |"
  FAIL=1
else
  say "    symlinks  none (all real content)"
fi

if grep -rqE '(/Users/|/home/|~/src/|\$HOME)' "$PI_CONFIG" \
     --include='*.json' --include='*.md' 2>/dev/null; then
  say "    PATHS     machine-specific paths in the repo:"
  grep -rnE '(/Users/|/home/|~/src/|\$HOME)' "$PI_CONFIG" \
     --include='*.json' --include='*.md' 2>/dev/null | sed 's|^|              |'
  FAIL=1
else
  say "    paths     clean (portable)"
fi

NT=$(find "$REPO_EXT" -maxdepth 1 -name '*.ts' 2>/dev/null | wc -l | tr -d ' ')
ND=$(find "$REPO_EXT" -maxdepth 2 -name 'index.ts' 2>/dev/null | wc -l | tr -d ' ')
TOT=$((NT + ND))
say "    loadable  $TOT extension(s) in the repo"
if [ "$TOT" -eq 0 ] && [ "$DRY" -eq 0 ]; then
  say "              ^ nothing for pi to load"
  FAIL=1
fi

if [ -f "$MAKEFILE" ]; then
  DUP=0
  for t in pi pi_check pi_vendor pi_unlink; do
    c=$(grep -cE "^$t *:" "$MAKEFILE" || true)
    [ "$c" -gt 1 ] && { say "    DUP       \`$t\` defined $c times"; DUP=1; FAIL=1; }
  done
  [ "$DUP" -eq 0 ] && say "    makefile  one definition per pi target"
fi

# --- 8. git --------------------------------------------------------------
head1 "8. Git"
if [ "$DRY" -eq 1 ]; then
  say "    would: git add configs/pi Makefile .gitignore"
else
  git -C "$DOTFILES" add configs/pi Makefile .gitignore 2>/dev/null || true
  git -C "$DOTFILES" status --short configs/pi Makefile .gitignore | sed 's|^|      |' || true
  if [ "$DO_COMMIT" -eq 1 ]; then
    if [ "$FAIL" -eq 0 ]; then
      git -C "$DOTFILES" commit -q -m "Sync pi coding agent configuration" || say "    nothing to commit"
      say "    committed"
    else
      say "    NOT committing — audit failed"
    fi
  fi
fi

# --- result -------------------------------------------------------------
if [ "$DRY" -eq 1 ]; then
  printf '\n\033[1;33m====================================\033[0m\n'
  printf '\033[1;33m  DRY RUN — NOTHING WAS WRITTEN\033[0m\n'
  printf '\033[1;33m====================================\033[0m\n'
  exit 0
fi

head1 "Result"
if [ "$FAIL" -eq 0 ]; then
  say "  Synced $COPIED item(s). Live config was read, never modified."
  say ""
  say "  make pi_check    # should print: configs/pi is self-contained."
  say "  Re-run this script whenever your pi config changes."
else
  say "  Audit FAILED. Your live config was not modified."
  say ""
  if [ "$TOT" -eq 0 ]; then
    say "  Nothing reached configs/pi/extensions. From the inventory above:"
    say "    * entries marked DANGLING have no content to copy — run --heal,"
    say "      then restore them, or get them from upstream: make pi_vendor"
    say "    * if extensions/ itself points into the repo, that link is a"
    say "      leftover from pi-sync v1/v2. Run --heal, then re-run."
  fi
  exit 1
fi
