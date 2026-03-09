Check for NOX AI Skills updates and install them from the CLI.

## Process

1. **Find the NOX repo** — check these locations in order:
   - `$NOX_SKILLS_DIR` (if set)
   - `$HOME/.nox`
   - `$HOME/NOX`
   - The directory containing symlink targets in `$HOME/.claude/commands/nox/` (if symlinked)
   - On Windows: `%USERPROFILE%\.nox` or `%USERPROFILE%\.cursor\projects\NOX`
   - If not found, offer to clone: `git clone https://github.com/LDGUEST/NOX.git $HOME/.nox`

2. **Check current version** — run from the repo directory:
   ```bash
   cd <repo_path>
   LOCAL_HASH=$(git rev-parse --short HEAD)
   LOCAL_DATE=$(git log -1 --format='%ci' HEAD | cut -d' ' -f1)
   git fetch origin main --quiet
   REMOTE_HASH=$(git rev-parse --short origin/main)
   ```

3. **Compare** — if `LOCAL_HASH == REMOTE_HASH`, report "Already up to date" and stop.

4. **Show what's new** — display commits between local and remote:
   ```bash
   echo "\nNew commits:"
   git log --oneline HEAD..origin/main
   COMMIT_COUNT=$(git rev-list --count HEAD..origin/main)
   ```
   Format as a clean list:
   ```
   NOX Update Available
   
   Installed: <LOCAL_HASH> (<LOCAL_DATE>)
   Latest:    <REMOTE_HASH>
   
   What's New (<COMMIT_COUNT> commits)
   ─────────────────────────────────
   <commit list>
   ```

5. **Ask to proceed** — confirm with the user before updating.

6. **Pull and reinstall**:
   ```bash
   cd <repo_path>
   git pull origin main
   bash install.sh
   ```
   If the original install used `--symlink`, the pull alone updates everything.
   Detect symlink mode: `[ -L "$HOME/.claude/commands/nox/update.md" ]`

7. **Report result**:
   ```
   NOX Updated: <OLD_HASH> -> <NEW_HASH>
   Restart your CLI session to pick up new skills.
   ```

## Error Handling

- If git working tree is dirty: warn and ask user if they want to stash first
- If git pull fails: show the error, suggest manual resolution
- If install.sh fails: show the error, note that `git pull` succeeded so files are updated

---
Nox
