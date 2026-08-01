# 🗂️ Repository Organization Plan

# SPDX-FileCopyrightText: 2026 openDesk Contributors
# SPDX-License-Identifier: Apache-2.0

## 🎯 Problem Statement

The root directory of `opendesk_git/` currently contains **45+ files**, including:
- Documentation files (*.md)
- Script files (*.sh)
- Text files (*.txt)
- Archive files
- Configuration files

This makes navigation difficult and violates best practices for repository organization.

---

## 🏗️ Proposed Organization

### Option 1: Create Dedicated Directories (Recommended)

```
opendesk_git/
├── docs/                          # All documentation
│   ├── zki/                      # ZKI IT-Grundschutz-Profil
│   │   ├── implementation/       # Implementation files
│   │   │   ├── START_HERE.md
│   │   │   ├── INDEX_ALL_ZKI_FILES.md
│   │   │   ├── VISUAL_SUMMARY.md
│   │   │   ├── DASHBOARD.md
│   │   │   ├── QUICK_REFERENCE.md
│   │   │   └── ...
│   │   ├── analysis/             # Gap analysis
│   │   │   ├── COMPREHENSIVE_GAP_ANALYSIS.md
│   │   │   ├── COMPREHENSIVE_GAP_ANALYSIS_PART2.md
│   │   │   └── COMPREHENSIVE_ANALYSIS_SUMMARY.md
│   │   ├── planning/             # Planning documents
│   │   │   ├── ACTION_PLAN_COMPLETE.md
│   │   │   └── ZKI_CRITICAL_ACTIONS.md
│   │   └── currently-in-root/    # Existing root files moved here
│   │       ├── AGENTS.md
│   │       ├── ANALYSIS_REPORT.md
│   │       ├── CHANGES.md
│   │       ├── IMPLEMENTATION_COMPLETE.md
│   │       ├── IMPLEMENTATION_SUMMARY.md
│   │       ├── FINAL_IMPLEMENTATION_SUMMARY.md
│   │       ├── SUMMARY.md
│   │       ├── UPGRADE_SUMMARY.md
│   │       ├── ZKI_IMPLEMENTATION_SUMMARY.md
│   │       └── ...
│   │
│   └── other/                    # Other documentation
│       ├── README.md
│       ├── README_ZKI_IMPLEMENTATION.md
│       └── ...
│
├── scripts/                       # All scripts
│   ├── deploy/                    # Deployment scripts
│   │   ├── DEPLOY_NOW.sh
│   │   ├── FIX_ISSUES.sh
│   │   ├── deploy-stalwart-final.sh
│   │   ├── deploy-stalwart-opencloud-only.yaml
│   │   ├── deploy-simple.sh
│   │   └── MERGE_ALL.sh
│   │
│   └── other/                     # Other scripts
│       ├── passvault.sh
│       └── GO.md
│
├── configs/                       # Configuration files
│   ├── opencloud-values-complete.yaml
│   ├── opencloud-values-final.yaml
│   ├── opencloud-values-root.yaml
│   ├── opencloud-values.yaml
│   ├── stalwart-values-static.yaml
│   ├── stalwart-values-v001.yaml
│   ├── stalwart-values-v011.yaml
│   └── config.json
│
├── archives/                      # Archive files
│   └── unmigrated.txt
│
└── _archive/                      # Existing archive directory
    └── ...

# Existing directories remain unchanged:
# ├── opendesk-edu/
# ├── opendesk/
# ├── k8up/
# ├── user_import/
# ├── etc.
```

### Option 2: Create a New Dedicated Repository

Create a separate repository for ZKI IT-Grundschutz-Profil documentation:

```bash
# New repository: opendesk-git/zki-it-grundschutz
zki-it-grundschutz/
├── README.md
├── START_HERE.md
├── INDEX_ALL_ZKI_FILES.md
├── VISUAL_SUMMARY.md
├── DASHBOARD.md
├── QUICK_REFERENCE.md
├── COMPREHENSIVE_GAP_ANALYSIS.md
├── COMPREHENSIVE_GAP_ANALYSIS_PART2.md
├── ACTION_PLAN_COMPLETE.md
├── COMPREHENSIVE_ANALYSIS_SUMMARY.md
├── ZKI_CRITICAL_ACTIONS.md
├── docs/
│   └── (all other ZKI-related documents)
└── scripts/
    └── (ZKI-specific scripts)
```

### Option 3: Hybrid Approach (Recommended)

1. **Move all ZKI-specific files** to `opendesk-edu/docs/zki/` (since ZKI is Edu-specific)
2. **Move general documentation** to `docs/`
3. **Keep existing structure** for non-documentation files

```
opendesk_git/
├── docs/                          # General documentation
│   ├── CHANGES.md
│   ├── IMPLEMENTATION_SUMMARY.md
│   ├── SUMMARY.md
│   ├── UPGRADE_SUMMARY.md
│   └── README.md
│
├── opendesk-edu/
│   ├── docs/                      # Edu-specific docs
│   │   ├── zki/                  # NEW: ZKI IT-Grundschutz-Profil
│   │   │   ├── START_HERE.md
│   │   │   ├── INDEX_ALL_ZKI_FILES.md
│   │   │   ├── VISUAL_SUMMARY.md
│   │   │   ├── DASHBOARD.md
│   │   │   ├── QUICK_REFERENCE.md
│   │   │   ├── COMPREHENSIVE_GAP_ANALYSIS.md
│   │   │   ├── COMPREHENSIVE_GAP_ANALYSIS_PART2.md
│   │   │   ├── ACTION_PLAN_COMPLETE.md
│   │   │   ├── COMPREHENSIVE_ANALYSIS_SUMMARY.md
│   │   │   └── ZKI_CRITICAL_ACTIONS.md
│   │   └── (other edu docs)
│   └── ... (existing edu structure)
│
├── scripts/                       # All scripts
│   ├── DEPLOY_NOW.sh
│   ├── FIX_ISSUES.sh
│   └── ...
│
└── (other existing directories)
```

---

## ✅ Recommendation: Option 3 (Hybrid Approach)

### Why Option 3?

1. **ZKI is Edu-specific**: The ZKI IT-Grundschutz-Profil implementation is primarily for openDesk Edu
2. **Logical grouping**: All ZKI files belong with the Edu variant
3. **Existing pattern**: `opendesk-edu/docs/` already exists for Edu documentation
4. **Minimal disruption**: Doesn't break existing file references
5. **Better organization**: Keeps related files together

### Benefits

- ✅ All ZKI files in one logical location
- ✅ Follows existing directory structure
- ✅ Easy to find and maintain
- ✅ Can be referenced as `opendesk-edu/docs/zki/`
- ✅ Maintains relationship with Edu implementation

---

## 📋 Implementation Plan

### Migration Script

```bash
#!/bin/bash
# migrate-zki-docs.sh

ZKI_FILES=(
    "START_HERE.md"
    "INDEX_ALL_ZKI_FILES.md"
    "VISUAL_SUMMARY.md"
    "DASHBOARD.md"
    "QUICK_REFERENCE.md"
    "COMPREHENSIVE_GAP_ANALYSIS.md"
    "COMPREHENSIVE_GAP_ANALYSIS_PART2.md"
    "ACTION_PLAN_COMPLETE.md"
    "COMPREHENSIVE_ANALYSIS_SUMMARY.md"
    "ZKI_CRITICAL_ACTIONS.md"
    "ZKI_GAPS_AND_IMPROVEMENTS.md"
    "ZKI_GAPS_PART2.md"
    "ZKI_IMPLEMENTATION_SUMMARY.md"
    "ZKI_IT_GRUNDSCHUTZ_ANALYSIS.md"
    "ZKI_IT_GRUNDSCHUTZ_CHECKLIST.md"
    "ZKI_IT_GRUNDSCHUTZ_IMPLEMENTATION_PLAN.md"
    "FINAL_IMPLEMENTATION_SUMMARY.md"
    "IMPLEMENTATION_COMPLETE.md"
)

# Create target directory
mkdir -p opendesk-edu/docs/zki

# Move files
for file in "${ZKI_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "Moving $file to opendesk-edu/docs/zki/"
        git mv "$file" "opendesk-edu/docs/zki/"
    fi
done

# Create README in new directory
cat > opendesk-edu/docs/zki/README.md << 'EOF'
# ZKI IT-Grundschutz-Profil Implementation

This directory contains all documentation for the ZKI IT-Grundschutz-Profil implementation.

## Quick Start

- [START_HERE.md](./START_HERE.md) - Your entry point
- [INDEX_ALL_ZKI_FILES.md](./INDEX_ALL_ZKI_FILES.md) - Complete file inventory
- [ZKI_CRITICAL_ACTIONS.md](./ZKI_CRITICAL_ACTIONS.md) - **MUST READ** - What blocks production

## Documentation

### Entry Points
- [START_HERE.md](./START_HERE.md)
- [INDEX_ALL_ZKI_FILES.md](./INDEX_ALL_ZKI_FILES.md)

### Visual Aids
- [VISUAL_SUMMARY.md](./VISUAL_SUMMARY.md)
- [DASHBOARD.md](./DASHBOARD.md)

### Analysis
- [COMPREHENSIVE_GAP_ANALYSIS.md](./COMPREHENSIVE_GAP_ANALYSIS.md)
- [COMPREHENSIVE_GAP_ANALYSIS_PART2.md](./COMPREHENSIVE_GAP_ANALYSIS_PART2.md)
- [COMPREHENSIVE_ANALYSIS_SUMMARY.md](./COMPREHENSIVE_ANALYSIS_SUMMARY.md)

### Planning
- [ACTION_PLAN_COMPLETE.md](./ACTION_PLAN_COMPLETE.md)
- [ZKI_CRITICAL_ACTIONS.md](./ZKI_CRITICAL_ACTIONS.md)

## Quick Links

- [Security Policies](../../security-policies/zki/) - IT Security Policy & Incident Response
- [Helm Charts](../../helmfile/charts/security/) - Kyverno policies and security chart
- [App Config](../../helmfile/apps/edu/security/) - Deployment configuration
EOF

# Commit changes
git add opendesk-edu/docs/zki/
git commit -m "refactor: Move ZKI documentation to opendesk-edu/docs/zki/"

echo "Migration complete!"
```

### Alternative: Move All Root Documentation

If you prefer to clean up the entire root directory:

```bash
#!/bin/bash
# migrate-all-docs.sh

# Create directories
mkdir -p docs
mkdir -p scripts
mkdir -p configs

# Move documentation files
git mv *.md docs/ 2>/dev/null

# Move script files
git mv *.sh scripts/ 2>/dev/null

# Move config files
git mv *.yaml configs/ 2>/dev/null
git mv *.json configs/ 2>/dev/null

# Keep specific files in root (if needed)
git mv docs/AGENTS.md .
git mv docs/README.md .
git mv scripts/passvault.sh .

# Commit
git add .
git commit -m "refactor: Organize repository structure"
```

---

## 🎯 Decision Guide

### Choose Option 1 (Dedicated Directories) if:
- You want to organize ALL files in the root
- You prefer a flat structure with clear categories
- You don't mind breaking existing references

### Choose Option 2 (New Repository) if:
- ZKI is a separate project with its own lifecycle
- You want independent versioning and releases
- You need separate access control

### Choose Option 3 (Hybrid - RECOMMENDED) if:
- ✅ ZKI is primarily for openDesk Edu
- ✅ You want to maintain existing structure
- ✅ You prefer logical grouping with related files
- ✅ Minimal disruption to existing workflows

---

## 📊 Comparison Matrix

| Criteria | Option 1 | Option 2 | Option 3 (Recommended) |
|----------|----------|----------|------------------------|
| Organization | ✅✅✅ | ✅✅✅ | ✅✅✅ |
| Logical Grouping | ✅✅ | ✅✅✅ | ✅✅✅ |
| Minimal Disruption | ✅ | ✅✅✅ | ✅✅✅ |
| Edu Integration | ✅✅ | ❌ | ✅✅✅ |
| Easy Navigation | ✅✅✅ | ✅✅✅ | ✅✅✅ |
| Repository Bloat | ✅✅✅ | ✅✅✅ | ✅✅ |
| Backward Compatibility | ❌ | ✅✅✅ | ✅✅✅ |
| Implementation Effort | ✅✅ | ✅ | ✅✅✅ |

---

## 🔧 Implementation Steps (For Option 3)

### Step 1: Create Target Directory
```bash
mkdir -p opendesk-edu/docs/zki
```

### Step 2: Move ZKI Files
```bash
cd /home/weissto_local/git/opendesk_git
git mv START_HERE.md opendesk-edu/docs/zki/
git mv INDEX_ALL_ZKI_FILES.md opendesk-edu/docs/zki/
git mv VISUAL_SUMMARY.md opendesk-edu/docs/zki/
git mv DASHBOARD.md opendesk-edu/docs/zki/
git mv QUICK_REFERENCE.md opendesk-edu/docs/zki/
git mv COMPREHENSIVE_GAP_ANALYSIS.md opendesk-edu/docs/zki/
git mv COMPREHENSIVE_GAP_ANALYSIS_PART2.md opendesk-edu/docs/zki/
git mv ACTION_PLAN_COMPLETE.md opendesk-edu/docs/zki/
git mv COMPREHENSIVE_ANALYSIS_SUMMARY.md opendesk-edu/docs/zki/
git mv ZKI_CRITICAL_ACTIONS.md opendesk-edu/docs/zki/
```

### Step 3: Update References (Optional)

Search and replace old references:
```bash
# Find all references to moved files
grep -r "START_HERE.md" --include="*.md" --include="*.yaml" .

# Update references (example)
sed -i 's/START_HERE\.md/opendesk-edu\/docs\/zki\/START_HERE.md/g' **/*.md
```

### Step 4: Create README
```bash
cat > opendesk-edu/docs/zki/README.md << 'EOF'
# ZKI IT-Grundschutz-Profil Implementation Documentation

## 📚 Documentation Index

### 🎯 Start Here
- [START_HERE.md](./START_HERE.md) - Your entry point to the implementation

### 📋 Quick References
- [INDEX_ALL_ZKI_FILES.md](./INDEX_ALL_ZKI_FILES.md) - Complete file inventory
- [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) - Cheat sheet

### 📊 Visual Aids
- [VISUAL_SUMMARY.md](./VISUAL_SUMMARY.md) - Visual dashboard
- [DASHBOARD.md](./DASHBOARD.md) - Metrics dashboard

### 🔍 Analysis
- [COMPREHENSIVE_GAP_ANALYSIS.md](./COMPREHENSIVE_GAP_ANALYSIS.md)
- [COMPREHENSIVE_GAP_ANALYSIS_PART2.md](./COMPREHENSIVE_GAP_ANALYSIS_PART2.md)
- [COMPREHENSIVE_ANALYSIS_SUMMARY.md](./COMPREHENSIVE_ANALYSIS_SUMMARY.md)

### 🚀 Action Plans
- [ACTION_PLAN_COMPLETE.md](./ACTION_PLAN_COMPLETE.md) - Complete 16-week plan
- [ZKI_CRITICAL_ACTIONS.md](./ZKI_CRITICAL_ACTIONS.md) - **P0 Actions (Blocking)**

## 🔗 Related Resources

- [Security Policies](../../security-policies/zki/) - IT Security Policy & Incident Response
- [Helm Charts](../../helmfile/charts/security/) - Kyverno policies and security chart
- [App Config](../../helmfile/apps/edu/security/) - Deployment configuration

---

**Note**: All files in this directory were moved from the root directory for better organization.
EOF
```

### Step 5: Commit Changes
```bash
git add opendesk-edu/docs/zki/
git commit -m "refactor: Organize ZKI documentation into opendesk-edu/docs/zki/

Move all ZKI IT-Grundschutz-Profil documentation files from root to
opendesk-edu/docs/zki/ for better organization and logical grouping.

Files moved:
- START_HERE.md
- INDEX_ALL_ZKI_FILES.md
- VISUAL_SUMMARY.md
- DASHBOARD.md
- QUICK_REFERENCE.md
- COMPREHENSIVE_GAP_ANALYSIS.md
- COMPREHENSIVE_GAP_ANALYSIS_PART2.md
- ACTION_PLAN_COMPLETE.md
- COMPREHENSIVE_ANALYSIS_SUMMARY.md
- ZKI_CRITICAL_ACTIONS.md

Signed-off-by: openDesk Team"
```

---

## 📝 Migration Checklist

- [ ] Choose organization option (Recommendation: Option 3)
- [ ] Create target directories
- [ ] Move files using `git mv` (preserves history)
- [ ] Create README files in new directories
- [ ] Update internal file references (search/replace)
- [ ] Test all links and references
- [ ] Commit changes with clear message
- [ ] Push to repository
- [ ] Communicate changes to team
- [ ] Update documentation navigation

---

## 🎯Recommendation Summary

**RECOMMEND Option 3**: Move all ZKI-specific files to `opendesk-edu/docs/zki/`

### Why?
1. **ZKI is Edu-focused** - The implementation is for openDesk Edu
2. **Existing structure** - `opendesk-edu/docs/` already exists
3. **Logical grouping** - All ZKI files together with related Edu files
4. **Minimal disruption** - Doesn't break existing workflows
5. **Better organization** - Reduces root directory clutter

### Expected Result
```
opendesk_git/
├── opendesk-edu/
│   └── docs/
│       └── zki/              # NEW: All ZKI files here
│           ├── README.md
│           ├── START_HERE.md
│           ├── INDEX_ALL_ZKI_FILES.md
│           ├── VISUAL_SUMMARY.md
│           ├── DASHBOARD.md
│           ├── QUICK_REFERENCE.md
│           ├── COMPREHENSIVE_GAP_ANALYSIS.md
│           ├── COMPREHENSIVE_GAP_ANALYSIS_PART2.md
│           ├── ACTION_PLAN_COMPLETE.md
│           ├── COMPREHENSIVE_ANALYSIS_SUMMARY.md
│           └── ZKI_CRITICAL_ACTIONS.md
└── ... (other directories unchanged)
```

**This reduces root directory files from 45+ to a more manageable number.**

---

## 📞 Next Steps

1. **Review Options**: Choose the organization option that best fits your needs
2. **Create Migration Script**: Use the provided scripts or create your own
3. **Test Migration**: Try on a branch first
4. **Review Changes**: Ensure all files are moved correctly
5. **Update References**: Search/replace old file paths
6. **Commit & Push**: Use clear commit messages
7. **Communicate**: Notify the team of the changes

Would you like me to execute the migration for Option 3 (moving ZKI files to `opendesk-edu/docs/zki/`)?
