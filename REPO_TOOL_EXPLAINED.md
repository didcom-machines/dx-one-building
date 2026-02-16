# Understanding Repo Tool - Why `.repo/manifest.xml`?

## Your Question
> "Why's it looking for manifest at the root of .repo while I requested it in .repo/manifests/default.xml?"

## The Answer: How Repo Tool Works

### Repo's Internal Structure

When you run `repo init`, the tool creates this structure:

```
.repo/
├── manifest.xml              ← SYMLINK! Always read by repo commands
├── manifests/                ← Checked out manifest repository
│   ├── .git → ../manifests.git
│   └── default.xml           ← Your actual manifest file
├── manifests.git/            ← Cloned manifest repository
│   ├── HEAD
│   ├── config
│   └── objects/
└── repo/                     ← Repo tool itself
```

### The Workflow

**1. `repo init -u <url> -b <branch> -m <manifest>`**

- Clones the git repository from `<url>` into `.repo/manifests.git/`
- Checks out branch `<branch>` to `.repo/manifests/`
- Looks for `<manifest>` file inside `.repo/manifests/` (default: `default.xml`)
- **Creates symlink:** `.repo/manifest.xml` → `.repo/manifests/<manifest>`

**2. All subsequent repo commands (sync, forall, etc.)**

- **Always read from `.repo/manifest.xml`** (the symlink)
- They don't use the `-u` or `-m` flags again
- The symlink points to the correct manifest in `.repo/manifests/`

### Why `.` Doesn't  Work

```bash
# BROKEN:
repo init -u . -m .repo/manifests/default.xml
```

**Problems:**
1. **`-u .` is not a Git URL** - Repo expects `https://`, `git://`, `ssh://`, or `file://`
2. **`-m` specifies filename, not path** - Repo automatically prepends `.repo/manifests/`
3. The argument should be: `-m default.xml` (just the filename)

### Correct Commands

#### For Local Development (using local git repo)
```bash
repo init -u file://$PWD -b main
```

- `file://$PWD` = Use current directory as git repository URL
- `-b main` = Use main branch
- No `-m` needed = Uses `default.xml` by default

#### For Cloud Build (using GitHub)
```bash
repo init -u https://github.com/didcom-machines/dx-one-building.git -b main
```

- Clones from GitHub
- Uses `default.xml` from the repository
- Works in CI/CD environments

### What `-m` Actually Does

The `-m` flag specifies **which file inside the manifest repository** to use:

```bash
# If your manifest repo has multiple manifests:
repo init -u <url> -b main -m production.xml
repo init -u <url> -b main -m development.xml
repo init -u <url> -b main -m testing.xml
```

Repo will look for these files at `.repo/manifests/production.xml`, etc.

**It does NOT accept arbitrary filesystem paths!**

### Common Mistakes

❌ **Wrong:** `repo init -u . -m /full/path/to/manifest.xml`
- `.` is not a URL
- Full paths don't work

❌ **Wrong:** `repo init -u . -m .repo/manifests/default.xml`
- `.` is not a URL
- This is specifying the wrong path

✅ **Correct:** `repo init -u file:///full/path/to/repo -b main`
- Proper file:// URL
- Repo finds manifest automatically

✅ **Correct:** `repo init -u file://$PWD -b main -m custom.xml`
- Proper file:// URL
- Custom manifest name (must exist in manifest repo)

## Real-World Example

### Your Project Structure
```
dx-one-building/               ← Git repository
├── .git/                      ← This is your manifest repository!
├── .repo/manifests/
│   └── default.xml            ← WHERE you PUT the manifest
├── sources/
│   └── ... (external layers go here)
└── ... (project files)
```

### What Happens Step-by-Step

**When you run:**
```bash
cd /home/manuelmonge/dx-one-building
repo init -u file://$PWD -b main
```

**Repo does this:**
1. Sees `file:///home/manuelmonge/dx-one-building` is a git repo ✓
2. Clones it into `.repo/manifests.git/` (well, it's already there)
3. Checks out `main` branch to `.repo/manifests/`
4. Looks for `default.xml` in `.repo/manifests/`
5. **Creates symlink:** `.repo/manifest.xml` → `manifests/default.xml`
6. Done! ✓

**When you run:**
```bash
repo sync -j8
```

**Repo does this:**
1. Reads `.repo/manifest.xml` (follows symlink to `manifests/default.xml`)
2. Parses all `<project>` entries
3. Clones/updates each project to its specified `path`
4. Done! All layers fetched to `sources/` ✓

## Summary

| What You Specify | What Repo Uses | Why |
|------------------|----------------|-----|
| `-u file://$PWD` | Git repository URL | Repo needs a git URL, not a path |
| `-b main` | Branch name | Which branch of manifest repo |
| `-m default.xml` | Filename only | Repo looks in `.repo/manifests/` |
| (nothing) | `.repo/manifest.xml` | Symlink to actual manifest |

**Key Insight:** Repo treats your `dx-one-building` repository as BOTH:
1. Your project repository (tracked in git)
2. Your manifest repository (used by repo)

This is perfectly valid! The manifest lives in the same repo as your project code.
