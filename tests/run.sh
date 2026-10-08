#!/bin/bash
# coolnight test suite: a local bare repo plays GitHub and two throwaway
# home folders play two Macs. Nothing outside a temp folder is touched, no
# network or GitHub login is needed, and no apps get installed.
#
#   bash tests/run.sh          (from anywhere; exits 1 if anything fails)

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
T=$(mktemp -d "${TMPDIR%/}/coolnight-test.XXXXXX")
A=$T/macA B=$T/macB
pass=0 fail=0
check() { if eval "$2"; then echo "PASS  $1"; pass=$((pass + 1)); else echo "FAIL  $1"; fail=$((fail + 1)); fi; }
sha() { shasum -a 256 "$1" | cut -d' ' -f1; }
inode() { stat -f %i "$1"; }
OMNI=.config/omniwm/settings.toml
run() { local home=$1; shift; (cd "$home" && HOME=$home COOLNIGHT_NO_SPLASH=1 bash "$home/.config/coolnight/install.sh" "$@" 2>&1); }
bootstrap() { cat "$ROOT/install.sh" | HOME=$1 bash -s -- --configs-only --no-open 2>&1; }
mkdir -p "$T/bin" "$A/Library/Fonts" "$B/Library/Fonts"
: >"$A/Library/Fonts/FiraCodeNerdFontMono-Regular.ttf"
: >"$B/Library/Fonts/FiraCodeNerdFontMono-Regular.ttf"

# a fake gh, logged in as "testuser"
cat >"$T/bin/gh" <<'GH'
#!/bin/bash
case "$1 $2" in
  "auth status") exit 0 ;;
  "api user") echo "testuser 123 Test User" ;;
  *) exit 0 ;;
esac
GH
chmod +x "$T/bin/gh"
export PATH="$T/bin:/opt/zerobrew/bin:/opt/homebrew/bin:$PATH" COOLNIGHT_REPO="$T/remote.git"
unset CLAUDECODE GIT_CONFIG_GLOBAL

# seed "GitHub" with this checkout's files
git init --quiet --bare -b main "$T/remote.git"
mkdir "$T/seed" && (cd "$ROOT" && tar cf - --exclude .git .) | (cd "$T/seed" && tar xf -)
git -C "$T/seed" init --quiet -b main
git -C "$T/seed" add -A
git -C "$T/seed" -c user.name=seed -c user.email=seed@example.com commit --quiet -m seed
git -C "$T/seed" push --quiet "$T/remote.git" main

# Mac B already has an old zshrc, a personal gitconfig, and a Ghostty
# config that would override ours
printf 'export WORK=1\nalias k=kubectl\n' >"$B/.zshrc"
printf '[user]\n\tname = B Person\n\temail = b@example.com\n' >"$B/.gitconfig"
mkdir -p "$B/Library/Application Support/com.mitchellh.ghostty"
printf 'font-size = 12\n' >"$B/Library/Application Support/com.mitchellh.ghostty/config"
# …and OmniWM already ran there once, writing its own default settings
mkdir -p "$B/.config/omniwm" && printf 'schemaVersion = 4\n# generated default\n' >"$B/$OMNI"

echo "── bootstrap, piped like curl | bash"
bootstrap "$A" >"$T/a-install.out"
bootstrap "$B" >"$T/b-install.out"
check "A cloned the repo"                     "[[ -d $A/.config/coolnight/.git ]]"
for f in $(cd "$ROOT/home" && find . -type f ! -name .DS_Store | sed 's|^\./||' | grep -v -x -F "$OMNI"); do
  check "A ~/$f is a link with the repo's bytes" "[[ -L $A/$f ]] && cmp -s $A/$f $ROOT/home/$f"
done
check "A OmniWM settings are a real file, not a link" "[[ -f $A/$OMNI && ! -L $A/$OMNI ]] && cmp -s $A/$OMNI $ROOT/home/$OMNI"
check "A remembers the synced version"         "grep -q \"\$(sha $A/$OMNI)  $OMNI\" $A/.local/state/coolnight/copies.base"
check "B's OmniWM default replaced by the repo's" "cmp -s $B/$OMNI $ROOT/home/$OMNI"
check "B's OmniWM default kept in the backup"  "grep -q 'generated default' $B/.local/state/coolnight/*/backup/$OMNI"
check "A got a ~/.gitconfig that includes the coolnight defaults" "grep -q 'coolnight.gitconfig' $A/.gitconfig"
check "A's git now pages through delta"       "HOME=$A git config core.pager | grep -q delta"
check "B old zshrc kept in .zshrc.local"      "grep -q '^# alias k=kubectl' $B/.zshrc.local"
check "B Ghostty override moved aside"        "[[ ! -e '$B/Library/Application Support/com.mitchellh.ghostty/config' ]]"
check "B's include sits above its own settings" "[[ \$(grep -n 'coolnight.gitconfig' $B/.gitconfig | cut -d: -f1) -lt \$(grep -n 'B Person' $B/.gitconfig | cut -d: -f1) ]]"
check "B keeps its own git identity"          "[[ \$(HOME=$B git config user.email) == b@example.com ]]"

echo "── re-running is a no-op"
bootstrap "$A" >"$T/a-rerun.out"
check "A re-run says already linked"          "grep -q 'already linked' $T/a-rerun.out"
check "A re-run made no new backup"           "[[ \$(ls -d $A/.local/state/coolnight/*/backup 2>/dev/null | wc -l) -eq 0 ]]"

echo "── A edits .zshrc and pushes; B pulls"
echo '# edited on A' >>"$A/.zshrc"
run "$A" status >"$T/a-status1.out"
check "A status shows the local change"       "grep -q 'changed on this Mac' $T/a-status1.out"
run "$A" push >"$T/a-push1.out"
check "A push committed and pushed"           "grep -q 'saved · Update .zshrc' $T/a-push1.out && grep -q 'push to GitHub' $T/a-push1.out"
check "commit author is the noreply id"       "[[ \$(git -C $A/.config/coolnight log -1 --format=%ae) == 123+testuser@users.noreply.github.com ]]"
run "$B" pull >"$T/b-pull1.out"
check "B pull got it, live through the link"  "tail -1 $B/.zshrc | grep -q 'edited on A'"
check "B pull hints to reload zsh"            "grep -q 'exec zsh' $T/b-pull1.out"

echo "── both Macs edit different files at once"
echo '# A again' >>"$A/.zshrc"
echo '# B starship' >>"$B/.config/starship.toml"
run "$A" push >"$T/a-push2.out"
run "$B" push >"$T/b-push2.out"
check "B push merged A's change too"          "grep -q \"also got the other Mac's changes · .zshrc\" $T/b-push2.out && tail -1 $B/.zshrc | grep -q 'A again'"
run "$A" pull >"$T/a-pull2.out"
check "A pull got B's starship change"        "tail -1 $A/.config/starship.toml | grep -q 'B starship'"

echo "── the same line on both Macs: a real conflict"
sed -i '' 's/^# A again$/# A wins?/' "$A/.config/coolnight/home/.zshrc"
sed -i '' 's/^# A again$/# B wins?/' "$B/.config/coolnight/home/.zshrc"
run "$A" push >"$T/a-push3.out"
run "$B" push >"$T/b-push3.out"
check "B push stops on the conflict"          "grep -q 'both Macs changed the same lines' $T/b-push3.out"
check "B's file is clean, still B's"          "grep -q '^# B wins?$' $B/.zshrc && ! grep -q '^<<<<<<<' $B/.zshrc"
check "B repo isn't stuck mid-rebase"         "[[ ! -d $B/.config/coolnight/.git/rebase-merge && ! -d $B/.config/coolnight/.git/rebase-apply ]]"
git -C "$B/.config/coolnight" reset --quiet --hard '@{u}'

echo "── safety nets on push"
echo 'export OPENAI_API_KEY=sk-abcdefghijklmnopqrstuvwxyz0123456789' >>"$A/.zshrc"
run "$A" push >"$T/a-push4.out"
check "push refuses a secret"                 "grep -q 'look like secrets' $T/a-push4.out"
check "nothing was committed"                 "[[ -z \$(git -C $A/.config/coolnight log '@{u}..HEAD' --oneline) ]]"
sed -i '' '/OPENAI_API_KEY/d' "$A/.config/coolnight/home/.zshrc"
printf 'if true; then\n' >>"$A/.zshrc"
run "$A" push >"$T/a-push5.out"
check "push refuses a broken .zshrc"          "grep -q 'configs are broken' $T/a-push5.out && grep -q '.zshrc' $T/a-push5.out"
sed -i '' '$d' "$A/.config/coolnight/home/.zshrc"
printf 'bell-features = sparkles\n' >>"$A/.config/ghostty/config"
run "$A" push >"$T/a-push6.out"
check "push refuses a broken Ghostty config"  "grep -q 'configs are broken' $T/a-push6.out && grep -q 'ghostty/config' $T/a-push6.out"
sed -i '' '$d' "$A/.config/coolnight/home/.config/ghostty/config"
run "$A" status >"$T/a-status2.out"
check "A is back in sync"                     "grep -q 'in sync with GitHub' $T/a-status2.out"

echo "── synced copies (OmniWM's settings)"
# OmniWM saves by writing a new file and renaming it over the old one
omniwm_save() { sed "$2" "$1/$OMNI" >"$1/$OMNI.tmp" && mv -f "$1/$OMNI.tmp" "$1/$OMNI"; }
omniwm_save "$A" 's/^animationSpeed = .*/animationSpeed = 2.0/'
run "$A" status >"$T/a-copy-status.out"
check "A status sees OmniWM's own save"        "grep -q 'omniwm/settings.toml' $T/a-copy-status.out"
run "$A" push >"$T/a-copy-push1.out"
check "A push sends it"                        "grep -q 'push to GitHub' $T/a-copy-push1.out"
b_inode=$(inode "$B/$OMNI")
run "$B" pull >"$T/b-copy-pull1.out"
check "B pull applies it"                      "grep -q '^animationSpeed = 2.0' $B/$OMNI"
check "B's file was written in place (OmniWM's watcher sees a save)" "[[ \$(inode $B/$OMNI) == $b_inode ]]"
check "B status is clean afterwards"           "run $B status | grep -q 'in sync with GitHub'"
omniwm_save "$A" 's/^size = 12.0/size = 14.0/'
omniwm_save "$B" 's/^hideEmptyWorkspaces = true/hideEmptyWorkspaces = false/'
run "$A" push >"$T/a-copy-push2.out"
run "$B" push >"$T/b-copy-push2.out"
check "B push merges both Macs' OmniWM edits"  "grep -q '^size = 14.0' $B/$OMNI && grep -q '^hideEmptyWorkspaces = false' $B/$OMNI"
run "$A" pull >"$T/a-copy-pull2.out"
check "A pull gets B's edit too"               "grep -q '^hideEmptyWorkspaces = false' $A/$OMNI && grep -q '^size = 14.0' $A/$OMNI"
omniwm_save "$A" 's/^animationSpeed = .*/animationSpeed = 2.5/'
omniwm_save "$B" 's/^animationSpeed = .*/animationSpeed = 3.0/'
run "$A" push >"$T/a-copy-push3.out"
run "$B" push >"$T/b-copy-push3.out"
check "the same OmniWM line on both: push stops" "grep -q 'both Macs changed the same lines' $T/b-copy-push3.out"
check "B keeps its own OmniWM setting, clean"  "grep -q '^animationSpeed = 3.0' $B/$OMNI && ! grep -q '^<<<<<<<' $B/$OMNI"
git -C "$B/.config/coolnight" reset --quiet --hard '@{u}'
run "$B" --configs-only --no-open >"$T/b-copy-take.out"
check "taking the repo's version applies it, B's edit backed up" "grep -q '^animationSpeed = 2.5' $B/$OMNI && grep -q '^animationSpeed = 3.0' $B/.local/state/coolnight/*/backup/$OMNI"
# both sides change while the repo is updated behind coolnight's back
omniwm_save "$B" 's/^animationSpeed = .*/animationSpeed = 9.0/'
omniwm_save "$A" 's/^size = 14.0/size = 16.0/'
run "$A" push >/dev/null
git -C "$B/.config/coolnight" pull --quiet --ff-only
run "$B" status >"$T/b-copy-status2.out"
check "both changed: status says merge by hand" "grep -q 'changed here and in the repo' $T/b-copy-status2.out"
run "$B" push >"$T/b-copy-push5.out"
check "push doesn't undo A's change"            "grep -q '^size = 16.0' $B/.config/coolnight/home/$OMNI && [[ -z \$(git -C $B/.config/coolnight status --porcelain) ]]"
check "B's own edit is still there"             "grep -q '^animationSpeed = 9.0' $B/$OMNI"
cp "$B/.config/coolnight/home/$OMNI" "$B/$OMNI"
run "$B" --configs-only --no-open >/dev/null
omniwm_save "$B" 's/^animationSpeed = .*/animationSpeed = 4.0/'
run "$B" pull >"$T/b-copy-pull3.out"
check "pull won't overwrite an unpushed OmniWM edit" "grep -q 'run coolnight push' $T/b-copy-pull3.out && grep -q '^animationSpeed = 4.0' $B/$OMNI"
omniwm_save "$B" 's/^\[gaps\]$/[gaps/'
run "$B" push >"$T/b-copy-push4.out"
check "push refuses a broken OmniWM file"      "grep -q 'configs are broken' $T/b-copy-push4.out && grep -q 'omniwm/settings.toml' $T/b-copy-push4.out"
git -C "$B/.config/coolnight" checkout --quiet -- "home/$OMNI" && cp "$B/.config/coolnight/home/$OMNI" "$B/$OMNI"
run "$B" --configs-only --no-open >/dev/null
check "B back in sync"                         "run $B status | grep -q 'in sync with GitHub'"
run "$A" pull >/dev/null

echo "── adding files"
printf 'set number\n' >"$A/.vimrc"
run "$A" add .vimrc >"$T/a-add.out"
check "A .vimrc is now a link"                "[[ -L $A/.vimrc ]] && grep -q 'set number' $A/.vimrc"
run "$A" push >"$T/a-push7.out"
run "$B" pull >"$T/b-pull7.out"
check "B got .vimrc linked"                   "[[ -L $B/.vimrc ]] && grep -q 'set number' $B/.vimrc"
printf 'token = abcdefghijklmnop\n' >"$A/.secretrc"
run "$A" add .secretrc >"$T/a-add2.out"
check "add refuses a file with a token"       "grep -q 'seems to contain a token' $T/a-add2.out && [[ ! -L $A/.secretrc ]]"
run "$A" add .gitconfig >"$T/a-add3.out"
check "add refuses the personal ~/.gitconfig" "grep -q 'personal details' $T/a-add3.out && [[ ! -L $A/.gitconfig ]]"

echo "── repair, links, dropped files"
cp "$A/.config/starship.toml" "$A/starship.tmp" && mv -f "$A/starship.tmp" "$A/.config/starship.toml"
run "$A" status >"$T/a-status3.out"
check "status flags a link a tool replaced"   "grep -q \"starship.toml isn't linked\" $T/a-status3.out"
run "$A" --configs-only --no-open >"$T/a-repair.out"
check "running coolnight relinks it"          "[[ -L $A/.config/starship.toml ]]"
git -C "$A/.config/coolnight" rm --quiet home/.vimrc && git -C "$A/.config/coolnight" commit --quiet -m 'stop syncing vimrc'
run "$A" push >"$T/a-push8.out"
run "$B" pull >"$T/b-pull8.out"
check "B's dangling .vimrc link removed"      "[[ ! -L $B/.vimrc && ! -e $B/.vimrc ]]"
echo '# unpushed' >>"$B/.zshrc"
run "$B" pull >"$T/b-pull9.out"
check "pull won't run over unpushed edits"    "grep -q 'run coolnight push' $T/b-pull9.out"
git -C "$B/.config/coolnight" checkout --quiet -- home/.zshrc

echo "── lock"
sleep 30 & holder=$!
mkdir -p "$A/.local/state/coolnight/lock" && echo $holder >"$A/.local/state/coolnight/lock/pid"
run "$A" pull >"$T/a-lock1.out"
check "a second run waits its turn"           "grep -q 'already running' $T/a-lock1.out"
kill $holder 2>/dev/null; wait $holder 2>/dev/null
run "$A" pull >"$T/a-lock2.out"
check "a stale lock is cleared"               "! grep -q 'already running' $T/a-lock2.out && grep -q 'up to date' $T/a-lock2.out"
check "the lock is released afterwards"       "[[ ! -e $A/.local/state/coolnight/lock ]]"

echo "── doctor, restore, version"
run "$A" doctor >"$T/a-doctor.out"
check "doctor sees every config linked"       "grep -q 'configs linked from' $T/a-doctor.out"
check "doctor finds the configs valid"        "grep -q 'configs valid' $T/a-doctor.out"
check "doctor checks the synced copy"          "grep -q 'settings.toml matches the repo (synced copy)' $T/a-doctor.out"
check "doctor sees git using coolnight"       "grep -q 'git uses the coolnight defaults' $T/a-doctor.out"
check "doctor: zsh starts with no errors"     "grep -q 'zsh starts in .* ms with no errors' $T/a-doctor.out"
check "doctor: in sync with GitHub"           "grep -q 'in sync with GitHub' $T/a-doctor.out"
run "$B" restore >"$T/b-restore-list.out"
check "restore lists B's backups"             "grep -q 'file(s)' $T/b-restore-list.out"
first=$(ls -1d "$B"/.local/state/coolnight/*/backup | head -1 | xargs dirname | xargs basename)
run "$B" restore "$first" >"$T/b-restore.out"
check "restore brings B's old zshrc back"     "[[ ! -L $B/.zshrc ]] && grep -q 'alias k=kubectl' $B/.zshrc"
run "$B" --configs-only --no-open >"$T/b-relink.out"
check "coolnight goes back to the links"      "[[ -L $B/.zshrc ]]"
run "$A" --version >"$T/a-version.out"
check "--version names the commit"            "grep -q '^coolnight [0-9a-f]\{7\}' $T/a-version.out"

echo
if ((fail == 0)); then
  rm -rf "$T"
  echo "passed $pass, failed $fail"
else
  echo "passed $pass, failed $fail   (outputs kept in $T)"
fi
((fail == 0))
