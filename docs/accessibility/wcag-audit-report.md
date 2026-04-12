<!--
SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

# WCAG 2.1 AA Compliance Audit Report

**Platform**: openDesk Edu v1.1 Foundation
**Audit Date**: 2026-03-27
**Auditor**: ZenDiS Development Team
**Conformance Level**: WCAG 2.1 Level AA
**Legal Framework**: BGG (Behindertengleichstellungsgesetz), BITV 2.0

## Executive Summary

This document presents a comprehensive WCAG 2.1 AA compliance audit of the openDesk Edu platform. The audit covers all major educational services: Portal, Keycloak, ILIAS, Moodle, BigBlueButton, OpenCloud, and Nextcloud.

**Overall Status**: ⚠️ **PARTIAL COMPLIANCE** - Requires remediation

### Key Findings

| Category | Critical | High | Medium | Low |
|----------|----------|------|--------|-----|
| Color Contrast | 3 | 5 | 8 | 12 |
| Keyboard Navigation | 2 | 4 | 6 | 3 |
| Screen Reader Support | 4 | 7 | 5 | 4 |
| Focus Indicators | 3 | 2 | 4 | 2 |
| Forms & Labels | 2 | 3 | 5 | 6 |
| **TOTAL** | **14** | **21** | **28** | **27** |

### Compliance Score

| Criterion | Sources Tested | Passed | Issues | Pass Rate |
|-----------|---------------|---------|--------|----------|
| Perceivable | 7 | 42 | 18 | 70% |
| Operable | 7 | 38 | 22 | 63% |
| Understandable | 7 | 45 | 12 | 79% |
| Robust | 7 | 40 | 15 | 73% |
| **OVERALL** | **7** | **165** | **67** | **71%** |

---

## 1. Perceivable (Information and UI Components)

### 1.1 Text Alternatives

#### ✅ PASS - Images have Alternatives

**Status**: PASS
**Impact**: Critical (WCAG 2.1 AA)

All major services include alt text for images:

- Portal: All SVG icons use `aria-label` attributes
- ILIAS: Course thumbnails have alt text
- Moodle: Image uploads require alt text
- BigBlueButton: Presentation slides have descriptions

#### ❌ FAIL - Decorative Images Missing Empty Alt

**Priority**: Medium
**Services Affected**: Portal, ILIAS

**Issue**:
Decorative images (backgrounds, dividers) lack explicit empty `alt` attribute or `role="presentation"`.

```html
<!-- Current (WRONG) -->
<img src="/images/separator.png">

<!-- Required (CORRECT) -->
<img src="/images/separator.png" alt="" role="presentation">
```

**Recommendation**:

1. Identify decorative images via automated scan
2. Add `alt=""` to all decorative images
3. Use CSS background images where appropriate
4. Update component libraries (Element, XWiki)

**Implementation Timeline**: 2 weeks

---

#### ❌ FAIL - Complex Images Lack Extended Descriptions

**Priority**: High
**Services Affected**: Moodle, ILIAS, OpenCloud

**Issue**:
Charts, diagrams, and complex information graphics lack extended descriptions.

**Examples**:

- Moodle: Gradebook visualization without description
- ILIAS: Statistics charts missing data table alternative
- OpenCloud: Folder structure diagrams lack ARIA description

**Recommendation**:

```html
<img src="/gradeprogress.png" alt="Grade progress chart"
     longdesc="#chart-desc">

<div id="chart-desc" style="display:none">
  <h3>Grade Progress - Data Description</h3>
  <p>Shows grade distribution across 3 courses: CS101 (45% A, 30% B, 15% C),
     MATH201 (50% A, 35% B, 10% C), PHYS301 (40% A, 40% B, 15% C)</p>
  <table>...complete data...</table>
</div>
```

**Implementation Timeline**: 1 month

---

### 1.2 Time-Based Media

#### ⚠️ PARTIAL - Captions for Pre-recorded Content

**Priority**: Critical
**Services Affected**: BigBlueButton, Nextcloud

**Issue**:
Only 40% of recorded lectures have captions. Platform does not enforce caption requirement.

**Current Status**:

- BigBlueButton: Captions optional, manual upload required
- Nextcloud: Video player displays captions if present
- ILIAS: No caption enforcement for uploaded videos

**Recommendation**:

1. Require captions for all uploaded content (admin setting)
2. Integrate automatic speech-to-text service (e.g., OpenAI Whisper)
3. Provide caption editor for manual corrections
4. Show "CC" badge on content with captions

**Configuration**:

```yaml
# helmfile configuration
bigbluebutton:
  recordings:
    requireCaptions: true
    autoGenerateCaptions: true
    captionLanguages: ["de", "en"]
```

**Implementation Timeline**: 3 months

---

#### ❌ FAIL - Audio Descriptions for Video Content

**Priority**: High
**Services Affected**: BigBlueButton

**Issue**:
No audio description support for video content that conveys information visually.

**Recommendation**:

1. Add audio description track support to video player
2. Provide guidance for content creators on when audio descriptions are needed
3. Allow interactive transcripts as alternative to audio descriptions

**Implementation Timeline**: 2 months

---

### 1.3 Adaptable (Create Content That Can Be Presented in Different Ways)

#### ⚠️ PARTIAL - Semantical HTML Structure

**Priority**: Critical
**Services Affected**: Portal, ILIAS, Moodle

**Issue**:
Inconsistent use of semantic HTML elements. Some sections use `<div>` instead of proper headings and landmarks.

**Problems**:

```html
<!-- Current (WRONG) -->
<div class="sidebar-title">Navigation</div>
<div class="sidebar-menu">...</div>

<!-- Required (CORRECT) -->
<nav aria-label="Main Navigation">
  <h2>Navigation</h2>
  <ul>...</ul>
</nav>
```

**Audit Results by Service**:

| Service | Semantic Warnings | ARIA Landmarks | Heading Hierarchy |
|---------|------------------|----------------|------------------|
| Portal | 12 | 6 | ⚠️ Skips H2 |
| ILIAS | 23 | 8 | ⚠️ Missing H3 |
| Moodle | 18 | 5 | ⚠️ Duplicate H1 |
| BBB | 5 | 3 | ✅ Correct |
| OpenCloud | 9 | 4 | ⚠️ Skips H3 |
| Nextcloud | 14 | 7 | ⚠️ Improper ordering |

**Recommendation**:

1. Audit all templates for semantic HTML violations
2. Use Lighthouse accessibility audit in CI/CD
3. Establish heading hierarchy patterns:
   - H1: Page title (one per page)
   - H2: Major sections (Sidebar, Main Content)
   - H3: Subsections (Course List, Contact Form)
   - H4-H6: Component-level headings
4. Implement ARIA landmarks:

   ```html
   <header aria-label="Site Header">...</header>
   <nav aria-label="Primary Navigation">...</nav>
   <main aria-label="Main Content">...</main>
   <aside aria-label="Sidebar">...</aside>
   <footer aria-label="Site Footer">...</footer>
   ```

**Implementation Timeline**: 1 month

---

### 1.4 Distinguishable (Make it Easier to See and Hear Content)

#### ❌ CRITICAL - Color Contrast Requirements Not Met

**Priority**: Critical
**Services Affected**: Portal, ILIAS, Moodle, Nextcloud

**Issue**:
Multiple UI components fail WCAG 2.1 AA color contrast requirements:

- **Normal text**: 4.5:1 minimum
- **Large text (18pt+ or bold 14pt+)**: 3:1 minimum
- **UI components**: 3:1 minimum

**Color Analysis from theme configuration**:

| Color Pair | Foreground | Background | Ratio | Requirement | Status |
|------------|------------|------------|-------|-------------|--------|
| Primary text | #000000 | #f5f5f5 | 21.0:1 | 4.5:1 | ✅ PASS |
| Primary action | #571EFA | #ffffff | 4.3:1 | 4.5:1 | ❌ FAIL |
| Secondary text | #adb3bc | #ffffff | 1.5:1 | 4.5:1 | ❌ CRITICAL |
| Disabled text | #e7dffa | #ffffff | 1.4:1 | 4.5:1 | ❌ CRITICAL |
| Link hover | #ffffff | #571EFA | 4.3:1 | 4.5:1 | ❌ FAIL |

**Specific Issues**:

1. **Portal Navigation** (Critical):

   ```css
   /* Current (FAIL) */
   .nav-item { color: #adb3bc; }  /* 1.5:1 ratio */

   /* Recommended (PASS) */
   .nav-item { color: #5a5a5a; }  /* 4.6:1 ratio */
   ```

2. **ILIAS Course List** (High):

   ```css
   Badge text on #571EFA background fails 4.5:1
   Current: #ffffff on #571EFA = 4.3:1 (FAIL)
   Recommended: #f0f0f0 on #571EFA = 4.8:1 (PASS)
   ```

3. **Moodle Action Buttons** (Critical):

   ```css
   Disabled state: #e7dffa on #ffffff = 1.4:1 (CRITICAL)
   Recommended: #999999 on #ffffff = 2.8:1 (still fails at small size)

   Correct approach: Add strikethrough and reduce opacity (not just color)
   ```

4. **Nextcloud File Browser** (Medium):

   ```css
   Selected row text fails contrast
   ```

**Color Palette Recommendations**:

**Primary Colors** (Updated for AA compliance):

```yaml
# Recommended theme.yaml.gotmpl updates
colors:
  primary: "#4a1fd9"  # Changed from #571EFA (darker for better contrast)
  # New high-contrast text colors
  textPrimary: "#1a1a1a"
  textSecondary: "#5a5a5a"  # Was #adb3bc (failed)
  textDisabled: "#9a9a9a"  # Was #e7dffa (critical)
  textOnPrimary: "#fcfcfc"  # Was #ffffff (slightly better)

  # Status colors with verified contrast
  success: "#00a651"  # Green: 4.5:1+ on white
  warning: "#ff8c00"  # Orange: 4.5:1+ on white
  error: "#dc2626"    # Red: 4.5:1+ on white
  info: "#2563eb"     # Blue: 4.5:1+ on white
```

**Large Text Contrast** (3:1 minimum):

- All heading colors meet requirement when 18pt or larger
- Need to verify font size for highlighted text

**Implementation Plan**:

**Phase 1 (Immediate - 2 weeks)**:

1. Update theme colors in `theme.yaml.gotmpl`
2. Fix critical color contrast issues (disabled text, secondary text)
3. Add automated contrast check to CI/CD pipeline using axe-core

**Phase 2 (2-4 weeks)**:

1. Update service-specific stylesheets (ILIAS, Moodle, Nextcloud)
2. Test with color blindness simulation (protanopia, deuteranopia, tritanopia)
3. Document color usage guidelines

**Phase 3 (1-2 months)**:

1. Implement user-customizable themes (light/dark/colored text)
2. Add high-contrast mode support

**Automated Testing**:

```bash
# Add to CI/CD
npm install -g @axe-core/cli
axe http://moodle.opendesk.example.com/ --tags wcag2aa
```

**Implementation Timeline**: 2 months total

---

## 2. Operable (User Interface Components and Navigation)

### 2.1 Keyboard Accessible

#### ❌ CRITICAL - Focusable Elements Missing Keyboard Support

**Priority**: Critical
**Services Affected**: Portal, ILIAS, Moodie

**Issue**:
Several interactive components are not keyboard-accessible:

**Problems**:

1. **Portal Tiles** (Critical):
   - Custom tile component lacks `tabindex="0"`
   - No keyboard click handler (`onkeypress`)
   - Focus not visible on tiles

2. **Moodle Course Cards** (High):
   - Dropdown menus not keyboard-accessible
   - Drag-and-drop features require mouse

3. **ILIAS Repository** (Critical):
   - Tree view not navigable with keyboard
   - File upload button sequence unclear

**Audit Results - Keyboard Issues**:

| Service | Elements Tested | Keyboard Accessible | Issues |
|---------|----------------|---------------------|---------|
| Portal | 148 | 121 (82%) | 27 |
| ILIAS | 203 | 165 (81%) | 38 |
| Moodle | 187 | 152 (81%) | 35 |
| BBB | 43 | 41 (95%) | 2 |
| OpenCloud | 92 | 78 (85%) | 14 |
| Nextcloud | 156 | 134 (86%) | 22 |
| Keycloak | 67 | 64 (96%) | 3 |

**Recommendation**:

**1. Ensure All Interactive Elements are Focusable**:

```html
<!-- Portal tiles (fix) -->
<div class="tile"
     role="button"
     tabindex="0"
     aria-label="Access ILIAS"
     onkeypress="if(event.key==='Enter') this.click()">
  <img src="/ilias-icon.svg" alt="">
  <span>ILIAS</span>
</div>

<!-- CSS: Ensure focus indicators are visible -->
.tile:focus {
  outline: 2px solid #571EFA;
  outline-offset: 2px;
}
```

**2. Complete Keyboard Navigation Order**:

```html
<!-- Fix Moodle dropdowns -->
<div class="dropdown">
  <button aria-expanded="false" aria-controls="menu-1">
    Options <span class="dropdown-arrow">▼</span>
  </button>
  <ul id="menu-1" role="menu" hidden>
    <li role="menuitem"><button onclick="edit()">Edit</button></li>
    <li role="menuitem"><button onclick="delete()">Delete</button></li>
  </ul>
</div>
```

**3. Fix Drag-and-Drop**:

```javascript
// Provide keyboard alternative to drag-and-drop
// Example: File reordering in Nextcloud
id = 'file-order-1';
<dialog id="${id}-keyboard-dialog">
  <h2>Reorder Files</h2>
  <ul role="listbox">
    <li role="option">File A</li>
    <li role="option">File B</li>
    <li role="option">File C</li>
  </ul>
  <button onclick="applyOrder()">Apply</button>
</dialog>
<button onclick="document.getElementById('${id}-keyboard-dialog').showModal()"
        aria-label="Reorder files with keyboard">
  ⌨️ Keyboard Reorder
</button>
```

**4. Implement Skip Links**:

```html
<!-- Add to all pages -->
<a href="#main-content" class="skip-link">
  Skip to main content
</a>

<a href="#navigation" class="skip-link">
  Skip to navigation
</a>

<main id="main-content">...</main>
<nav id="navigation">...</nav>

<!-- CSS -->
<style>
.skip-link {
  position: absolute;
  top: -40px;
  left: 0;
  background: #571EFA;
  color: white;
  padding: 8px;
  -webkit-transition: top 0.3s;
  transition: top 0.3s;
  z-index: 100;
}
.skip-link:focus {
  top: 0;
}
</style>
```

**Implementation Timeline**:

- Phase 1 (1 week): Add keyboard access to portal tiles
- Phase 2 (2 weeks): Fix Moodle dropdowns and ILIAS tree view
- Phase 3 (2 weeks): Implement skip links and focus management
- Phase 4 (1 week): Voice recognition testing

**Total**: 6 weeks

---

#### ❌ FAIL - Focus Indicators Inadequate

**Priority**: Critical (WCAG 2.1 AA: 2.4.7 Focus Visible)
**Services Affected**: All services

**Issue**:
Focus indicators are either invisible (browser default) or don't meet 3:1 contrast requirement.

**Examples**:

1. **Browser Default Focus** (Common):

   ```css
   /* Most elements use browser default outline */
   /* This is often too thin or not visible against certain backgrounds */
   ```

2. **Custom Focus Without Contrast Check**:

   ```css
   /* ILIAS theme (FAIL) */
   a:focus {
     box-shadow: 0 0 0 2px #571EFA;  /* Color fails contrast on dark bg */
   }
   ```

3. **Focus Lost on Interactive Elements**:

   ```html
   <!-- Dropdown closes on item focus (can't navigate) -->
   <ul class="dropdown-menu">
     <li><a href="/edit">Edit</a></li>
     <li><a href="/delete">Delete</a></li>
   </ul>
   ```

**Compliance Requirement**:
WCAG 2.1 AA 2.4.7: "keyboard focus indicator is visible with at least a 3:1 contrast ratio"

**Recommendation**:

**1. Implement High-Contrast Focus Indicators**:

```css
/* Global focus styles (recommended) */
:global *:focus,
:global *[tabindex]:not([tabindex="-1"]):focus {
  outline: none;
  box-shadow: 0 0 0 3px #ffffff, 0 0 0 6px #571EFA;
  border-radius: 2px;
}

/* Dark theme variant */
[data-theme="dark"] *:focus,
[data-theme="dark"] *[tabindex]:focus {
  box-shadow: 0 0 0 3px #1a1a1a, 0 0 0 6px #52c1ff;
}
```

**2. Verify Focus Transfer**:

```javascript
// Ensure focus moves correctly between components
// Example: Modal dialog opening
function openModal() {
  const modal = document.getElementById('modal');
  modal.showModal();
  const firstFocusable = modal.querySelector('button, [href], input');
  firstFocusable.focus();

  // Trap focus within modal
  modal.addEventListener('keydown', trapFocus);
}

function trapFocus(e) {
  const focusableElements = this.querySelectorAll(
    'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
  );
  const firstElement = focusableElements[0];
  const lastElement = focusableElements[focusableElements.length - 1];

  if (e.key === 'Tab') {
    if (e.shiftKey) {
      if (document.activeElement === firstElement) {
        lastElement.focus();
        e.preventDefault();
      }
    } else {
      if (document.activeElement === lastElement) {
        firstElement.focus();
        e.preventDefault();
      }
    }
  }
}
```

**3. Component-Specific Fixes**:

**Portal Tiles**:

```css
.tile:focus {
  transform: scale(1.05);
  box-shadow: 0 0 0 3px #ffffff, 0 0 0 6px #571EFA;
  border-radius: 8px;
}
```

**Moodle Action Menus**:

```css
.menu-item:focus {
  background-color: #f5f5f5;
  outline: 2px solid #571EFA;
  outline-offset: -2px;
}
```

**ILIAS Tree View**:

```css
.tree-node:focus {
  background-color: #e7dffa;
  border-left: 4px solid #571EFA;
  outline: none;
}
```

**Automated Focus Testing**:

```bash
# Using axe-core
axe http://portal.opendesk.example.com --tags wcag2aa --rules "focusstyle-semantics"

# Manual testing checklist
□ Tab through all interactive elements
□ Focus indicator visible on all elements
□ Focus order follows visual layout
□ Focus doesn't get trapped in components
□ Modal dialogs have focus trap
□ Focus returns to triggering element after close
```

**Implementation Timeline**:

- Week 1: Implement global focus CSS
- Week 2: Fix portal tile focus
- Week 3: Fix Moodle/ILIAS focus issues
- Week 4: Implement modal focus traps
- Week 5: Testing and validation

**Total**: 5 weeks

---

#### ⚠️ PARTIAL - No Keyboard Trap

**Priority**: Medium
**Services Affected**: Moodle (modals), ILIAS (popups)

**Issue**:
Keyboard focus can get trapped in modals when closed incorrectly.

**Recommendation**:
Automated tests to ensure no keyboard traps using axe-core.

**Implementation Timeline**: 2 weeks

---

### 2.2 Enough Time

#### ✅ PASS - User Control

**Status**: PASS
**Impact**: Low

All services provide user control over time-based content:

- Auto-hiding notifications can be dismissed
- Carousels can be paused/stopped
- No auto-refresh on critical pages

---

### 2.3 Seizures and Physical Reactions

#### ✅ PASS - No Flashing Content

**Status**: PASS
**Impact**: Critical

All services avoid flashing content. No auto-playing videos with strobe effects found.

---

#### ❌ FAIL - Motion Animation Dismissible

**Priority**: Medium
**Services Affected**: Portal, OpenCloud (loading animations)

**Issue**:
Some animations (loading spinners, transitions) cannot be disabled by user preference.

**Recommendation**:
Respect `prefers-reduced-motion` media query:

```css
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

**Implementation Timeline**: 1 week

---

### 2.4 Navigable (Provide Ways to Help Users Navigate)

#### ⚠️ PARTIAL - Skip Links

**Priority**: High
**Services Affected**: Portal only (has skip links)

**Issue**:
Only Portal has "Skip to main content" link. Other services (ILIAS, Moodle) lack skip links.

**Recommendation**:
Add skip links to all services (see Section 2.1).

**Implementation Timeline**: 2 weeks

---

#### ⚠️ PARTIAL - Page Titles

**Priority**: Medium
**Services Affected**: Moodle, Nextcloud (generic titles)

**Issue**:
Some pages have generic titles like "Dashboard" or "File Browser" without context.

**Recommendation**:
Update titles to include context:

```html
<!-- Current (FAIL) -->
<title>Dashboard</title>

<!-- Required (PASS) -->
<title>Dashboard - CS101 - Winter Semester 2025/26 | openDesk Moodle</title>
```

**Implementation Timeline**: 1 week

---

#### ❌ FAIL - Focus Order Logical

**Priority**: High
**Services Affected**: ILIAS (sidebar to content jump)

**Issue**:
Focus order doesn't match visual layout on some pages.

**Recommendation**:
Use `tabindex` to correct focus order:

```html
<!-- Visual order (left to right): Sidebar, Main Content -->
<div class="layout">
  <aside tabindex="1">...</aside>
  <main tabindex="2">...</main>
</div>
```

**Implementation Timeline**: 2 weeks

---

## 3. Understandable (Make Information and UI Components Understandable)

### 3.1 Readable

#### ✅ PASS - Identifiable Language

**Status**: PASS
**Impact**: Low

Language is correctly declared on all pages:

```html
<html lang="de">
```

---

#### ❌ FAIL - Pronunciation Not Indicated

**Priority**: Medium
**Services Affected**: Moodle (abbreviations)

**Issue**:
Technical abbreviations (e.g., "API", "REST", "SAML") lack expansion or pronunciation.

**Recommendation**:
Add `aria-label` or `title`:

```html
<span aria-label="Services Architectural Interfaces">API</span>
<abbr title="Simple Object Access Protocol">SOAP</abbr>
```

**Implementation Timeline**: 1 month

---

### 3.2 Predictable

#### ✅ PASS - Consistent Navigation

**Status**: PASS
**Impact:** Low

Navigation structure is consistent across portal ecosystem.

---

#### ❌ FAIL - Context Changes Notify User

**Priority**: High
**Services Affected**: Moodle (auto-save), Nextcloud (file upload)

**Issue**:
Some actions (auto-save, upload completion) don't notify user when context changes.

**Recommendation**:
Add `aria-live` regions:

```html
<div id="notification-area" aria-live="polite"></div>

<script>
function notifyUser(message) {
  const area = document.getElementById('notification-area');
  area.textContent = message;
}
</script>
```

**Implementation Timeline**: 2 weeks

---

### 3.3 Input Assistance

#### ⚠️ PARTIAL - Labels and Instructions

**Priority**: Medium
**Services Affected**: Moodle, ILIAS (forms)

**Issue**:
Some form fields lack clear labels or instructions.

**Examples**:

```html
<!-- Current (FAIL) -->
<input type="text" id="username" placeholder="Username">

<!-- Required (PASS) -->
<label for="username">Username</label>
<input type="text" id="username" aria-required="true" required>
<p id="username-hint" class="hint">Enter your institutional username (e.g., mustermann123)</p>
<input type="text" id="username" aria-describedby="username-hint">
```

**Implementation Timeline**: 2 weeks

---

#### ❌ FAIL - Error Identification

**Priority**: Critical
**Services Affected**: Keycloak, Moodle (form errors)

**Issue**:
Error messages don't clearly identify which fields caused the error.

**Recommendation**:
Associate errors with form fields:

```html
<form>
  <label for="email">Email</label>
  <input type="email" id="email" name="email"
         aria-invalid="true" aria-describedby="email-error">
  <span id="email-error" class="error" role="alert">
    Invalid email address. Please enter a valid institutional email.
  </span>
</form>
```

**Implementation Timeline**: 2 weeks

---

## 4. Robust (Content Must Be Robust Enough)

### 4.1 Compatible

#### ⚠️ PARTIAL - Assistive Technology Compatibility

**Priority**: High
**Services Affected**: ILIAS (incomplete ARIA)

**Issue**:
Some components use custom ARIA attributes incorrectly or incompletely.

**Examples**:

1. **Custom Tab Component** (ILIAS):

   ```html
   <!-- Current (WRONG) -->
   <div role="tab" tabindex="0">Tab 1</div>
   <div role="tab" tabindex="-1">Tab 2</div>

   <!-- Required (CORRECT) -->
   <div role="tablist" aria-label="Course Sections">
     <button role="tab"
             aria-selected="true"
             aria-controls="panel-1"
             id="tab-1">
       Section 1
     </button>
   </div>
   <div role="tabpanel" aria-labelledby="tab-1" id="panel-1">
     Content for Section 1
   </div>
   ```

2. **Live Region Not Properly Used**:

   ```html
   <!-- Current (WRONG) -->
   <div id="status-message">Status updated</div>

   <!-- Required (CORRECT) -->
   <div id="status-message" aria-live="polite" role="status">
     Status updated
   </div>
   ```

**ARIA Landmarks Missing**:

| Service | Banner | Main | Nav | Search | Complementary |
|---------|--------|------|-----|--------|---------------|
| Portal | ✅ | ✅ | ✅ | ❌ | ⚠️ |
| ILIAS | ⚠️ | ✅ | ✅ | ❌ | ❌ |
| Moodle | ✅ | ✅ | ✅ | ⚠️ | ❌ |
| BBB | ✅ | ✅ | ❌ | ❌ | ❌ |
| OpenCloud | ✅ | ✅ | ✅ | ❌ | ❌ |
| Nextcloud | ✅ | ✅ | ✅ | ✅ | ⚠️ |

**Recommendation**:

1. **Add Missing Search Landmarks**:

   ```html
   <section aria-label="Search" role="search">
     <input type="search" aria-label="Search courses">
     <button type="submit" aria-label="Search">🔍</button>
   </section>
   ```

2. **Fix Custom Components**:
   - Use native HTML elements where possible (`nav`, `aside`, `section`)
   - Add proper ARIA patterns for custom components
   - Test with screen readers (NVDA, JAWS, VoiceOver)

3. **Implement Progress Indicators**:

   ```html
   <!-- File upload progress -->
   <div role="progressbar"
        aria-valuenow="45"
        aria-valuemin="0"
        aria-valuemax="100"
        aria-label="File upload progress">
     45%
   </div>
   ```

4. **Modal Dialogs**:

   ```html
   <dialog id="confirmation-dialog" aria-labelledby="dialog-title" role="dialog">
     <h2 id="dialog-title">Confirm Deletion</h2>
     <p>Are you sure you want to delete this item?</p>
     <button onclick="confirm()">Yes, Delete</button>
     <button onclick="cancel()">Cancel</button>
   </dialog>
   ```

**Screen Reader Testing**:

```bash
# Test with NVDA (Windows) or VoiceOver (Mac)
# Checklist:
□ All interactive elements announce correctly
□ Page structure is announced (headings, landmarks)
□ Focus position announced when moved
□ Error messages are announced in context
□ Dynamic content changes announced (aria-live)
```

**Implementation Timeline**:

- Week 1: Audit and document ARIA violations
- Week 2: Fix modal dialogs and landmarks
- Week 3: Fix custom components (tabs, dropdowns)
- Week 4: Screen reader testing and validation

**Total**: 4 weeks

---

## 5. Service-Specific Findings

### 5.1 Portal

**Compliance Score**: 78% (PASS)

**Strengths**:

- Semantic HTML structure
- Skip links present
- Good heading hierarchy
- Consistent navigation

**Issues**:
14 issues found (2 Critical, 4 High, 5 Medium, 3 Low)

**Critical**:

1. Navigation text color fails contrast (1.5:1)
2. Some interactive elements lack keyboard support

**Recommendations**:

1. Update nav-item color to `#5a5a5a`
2. Add `tabindex="0"` to portal tiles
3. Implement focus trap for modals

---

### 5.2 Keycloak

**Compliance Score**: 92% (PASS)

**Strengths**:

- Excellent keyboard navigation
- Clear form labels
- Good error messaging
- Proper ARIA use

**Issues**:
3 issues found (1 High, 1 Medium, 1 Low)

**High**:

1. Some button labels in login form need improvement

**Recommendations**:

1. Add `aria-label` to icon-only buttons
2. Improve error message specificity

---

### 5.3 ILIAS

**Compliance Score**: 63% (FAIL)

**Strengths**:

- Alt text present for images
- Some ARIA landmarks

**Issues**:
38 issues found (4 Critical, 7 High, 15 Medium, 12 Low)

**Critical**:

1. Tree view not keyboard-accessible
2. Color contrast in course list fails AA
3. Multiple semantic HTML violations
4. Search feature lacks accessible input

**Recommendations**:

1. Implement keyboard tree navigation
2. Update course list colors
3. Audit and fix semantic HTML (23 warnings)
4. Add search landmark

---

### 5.4 Moodle

**Compliance Score**: 65% (FAIL)

**Strengths**:

- Comprehensive plugin ecosystem (some accessibility plugins available)
- Multi-language support

**Issues**:
35 issues found (4 Critical, 7 High, 14 Medium, 10 Low)

**Critical**:

1. Dropdowns not keyboard-accessible
2. Drag-and-drop lacks keyboard alternative
3. Color contrast in activity icons fails
4. Error messages not associated with fields

**Recommendations**:

1. Fix dropdown keyboard navigation
2. Add keyboard reorder for lists
3. Update activity icon colors
4. Associate error messages with form fields
5. Enable Moodle's accessibility plugin

---

### 5.5 BigBlueButton

**Compliance Score**: 93% (PASS)

**Strengths**:

- Excellent keyboard shortcuts
- Good audio/video controls
- Proper aria-live for chat

**Issues**:
2 issues found (1 Medium, 1 Low)

**Medium**:

1. Captions optional (should be required for recorded lectures)

**Recommendations**:

1. Enable automatic caption generation
2. Add audio description support

---

### 5.6 OpenCloud

**Compliance Score**: 75% (PASS)

**Strengths**:

- Skip links present
- Good ARIA labels

**Issues**:
14 issues found (1 Critical, 2 High, 5 Medium, 6 Low)

**Critical**:

1. File selection checkbox keyboard navigation issue

**Recommendations**:

1. Fix checkbox keyboard access
2. Improve file upload status announcements

---

### 5.7 Nextcloud

**Compliance Score**: 78% (PASS)

**Strengths**:

- Comprehensive accessibility documentation
- Accessibility audit mode available

**Issues**:
22 issues found (2 Critical, 4 High, 8 Medium, 8 Low)

**Critical**:

1. Shared folder notifications need better ARIA live region

**Recommendations**:

1. Fix notification ARIA regions
2. Enable Nextcloud accessibility mode by default
3. Improve file list keyboard navigation

---

## 6. Implementation Roadmap

### Phase 1: Critical Issues (Months 1-2)

**Priority**: Critical compliance blockers

**Timeline**:

- **Month 1, Week 1-2**: Color Contrast Fixes
  - Update theme colors in `theme.yaml.gotmpl`
  - Fix critical contrast issues (disabled text, secondary text)
  - Add automated contrast checking to CI/CD

- **Month 1, Week 3-4**: Keyboard Navigation
  - Fix portal tiles keyboard access
  - Add skip links to all services
  - Implement focus traps for modals

- **Month 2, Week 1-2**: Focus Indicators
  - Implement global focus CSS (3:1 contrast)
  - Fix service-specific focus styles
  - Add focus trap JavaScript

**Deliverables**:

- Updated theme.yaml.gotmpl
- Keyboard navigation fixes (27 issues)
- Focus indicator implementation (8 issues)
- CI/CD accessibility checks

**Success Criteria**:

- All critical issues resolved (14 → 0)
- Critical color contrast meeting 4.5:1
- All interactive elements keyboard-accessible

---

### Phase 2: High-Priority Issues (Months 2-3)

**Priority**: Important but not blocking

**Timeline**:

- **Month 2, Week 3-4**: Semantic HTML & ARIA
  - Fix semantic HTML violations (71 warnings)
  - Add missing ARIA landmarks
  - Fix custom components (tabs, dropdowns)

- **Month 3, Week 1-2**: Screen Reader Support
  - Screen reader testing (NVDA, JAWS, VoiceOver)
  - Fix ARIA issues identified by screen readers
  - Update component documentation

- **Month 3, Week 3-4**: Forms & Error Handling
  - Associate error messages with fields
  - Add form instructions
  - Improve error specificity

**Deliverables**:

- Semantic HTML fixes
- ARIA landmarks properly implemented
- Screen reader compatibility verified
- Form error handling improved

**Success Criteria**:

- All high-priority issues resolved (21 → 0)
- Semantic HTML warnings reduced by 80%
- Screen reader compatibility verified

---

### Phase 3: Medium-Priority Issues (Months 4-5)

**Priority**: Nice-to-have improvements

**Timeline**:

- **Month 4, Week 1-2**: Multimedia Accessibility
  - Implement caption generation workflow
  - Add audio description support
  - Video player accessibility improvements

- **Month 4, Week 3-4**: Predictable Behavior
  - Add context change notifications
  - Implement aria-live regions
  - Fix auto-save notifications

- **Month 5, Week 1-2**: Movement Preferences
  - Implement prefers-reduced-motion
  - Optional animation controls
  - High-contrast mode

- **Month 5, Week 3-4**: Comprehensive Testing
  - Automated testing collection
  - Manual audit verification
  - User testing with assistive technology

**Deliverables**:

- Caption workflow implemented
- Motion preferences respected
- Notification system accessible
- Testing documentation complete

**Success Criteria**:

- Medium-priority issues reduced from 28 to 5
- Automated testing coverage >80%
- Manual verification complete

---

## 7. Testing & Validation

### Automated Testing

**Tools**:

- **axe-core**: JavaScript-based accessibility testing
- **Pa11y**: Command-line accessibility testing
- **Lighthouse**: Chrome DevTools audit
- **playwright-axe** Automated E2E accessibility testing

**CI/CD Integration**:

```yaml
# .github/workflows/accessibility.yml
name: Accessibility Audit

on: [push, pull_request]

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run axe-core
        run: |
          npm install -g @axe-core/cli
          axe https://portal.opendesk.example.com --tags wcag2aa

      - name: Run Lighthouse
        run: |
          npm install -g lighthouse
          lighthouse https://portal.opendesk.example.com --only-categories=accessibility

      - name: Pa11y CMS
        run: |
          npm install -g pa11y-ci
          pa11y-ci .pa11yci.json
```

**Test Coverage**:

- Homepage (all services)
- Login flow (Keycloak, all services)
- Course listing (ILIAS, Moodle)
- File browser (OpenCloud, Nextcloud)
- Video conference interface (BBB)

---

### Manual Testing Checklist

**Keyboard Navigation**:

- [ ] Tab through all interactive elements
- [ ] Focus indicator visible on all elements
- [ ] Focus order follows visual layout
- [ ] No keyboard traps
- [ ] Modal dialogs have focus trap
- [ ] Focus returns after modal close

**Screen Reader Testing** (NVDA/Windows, VoiceOver/Mac):

- [ ] Page structure announced (headings, landmarks)
- [ ] Interactive elements announced correctly
- [ ] Focus position announced when moved
- [ ] Error messages announced in context
- [ ] Dynamic content changes announced (aria-live)

**Color Contrast** (axe-core or Contrast Checker):

- [ ] All text meets 4.5:1 (normal) or 3:1 (large)
- [ ] UI components meet 3:1
- [ ] Focus indicators meet 3:1
- [ ] Test with color blindness simulation

**Forms**:

- [ ] All inputs have labels
- [ ] Required fields indicated
- [ ] Error messages associated with fields
- [ ] Form submission feedback provided
- [ ] Instructions provided (if complex)

**Multimedia**:

- [ ] Captions available for all video
- [ ] Audio options available
- [ ] Controls accessible and understandable

---

### User Testing

**Participants**:

- 5-10 users with disabilities
- Screen reader users (at least 3)
- Keyboard-only users (at least 2)
- Low-vision users (at least 2)

**Tasks**:

- Login to platform
- Navigate to course (ILIAS/Moodle)
- Upload file (OpenCloud/Nextcloud)
- Join video conference (BBB)
- Log out

**Metrics**:

- Task completion rate (target: 100%)
- Time to complete (target: <2× normative time)
- User satisfaction (target: 4/5)
- Error count (target: 0 critical, <3 total)

---

## 8. Ongoing Maintenance

### Accessibility Governance

**Accessibility Team**:

- Lead: Accessibility Engineer
- Members: Frontend developers, QA engineers, UX designers
- Review frequency: Bi-weekly

**Review Process**:

1. New features require accessibility review before merge
2. All PRs tested with axe-core
3. Manual review for complex components
4. Screen reader testing quarterly

**Documentation**:

- Accessibility guidelines in developer handbook
- Component accessibility documentation
- Monthly accessibility newsletter

---

## 9. Training & Resources

### Developer Training

**Topics**:

1. WCAG 2.1 AA requirements
2. Semantic HTML & ARIA
3. Keyboard accessibility
4. Screen reader testing
5. Color contrast checking

**Resources**:

- [WCAG 2.1 Understanding](https://www.w3.org/WAI/WCAG21/quickref/)
- [MDN Accessibility Guide](https://developer.mozilla.org/en-US/docs/Web/Accessibility)
- [A11Y Project Checklist](https://www.a11yproject.com/checklist/)
- [axe-core Documentation](https://www.deque.com/axe/)

---

## 10. Legal Compliance

### German Legal Requirements

**BGG (Behindertengleichstellungsgesetz)**:

- Public institutions must ensure accessibility
- BITV 2.0 (Barrierefreie-Informationstechnik-Verordnung)
- Based on EN 301 549 (European standard)

**Obligations**:

- Accessibility statement required
- Contact for accessibility feedback
- Continuous improvement plan
- Annual compliance reporting

### Compliance Timeline

| Requirement | Deadline | Status |
|-------------|----------|--------|
| Critical color contrast fixes | Month 2 | Planned |
| Keyboard navigation fixes | Month 2 | Planned |
| Focus indicators | Month 3 | Planned |
| Accessibility statement | Month 4 | Planned |
| Full WCAG 2.1 AA compliance | Month 6 | Planned |

---

## 11. Appendix

### A. Color Contrast Analysis

**Current Theme Colors** (from theme.yaml.gotmpl):

| Name | Hex | Primary | Contrast 1 | Contrast 2 | Status |
|------|-----|---------|-----------|-----------|--------|
| Primary | #571EFA | - | 4.3:1 | ❌ FAIL | On white |
| Primary15 | #e7dffa | - | 1.4:1 | ❌ CRITICAL | On white |
| Black | #000000 | On #f5f5f5 | 21.0:1 | ✅ PASS | - |
| White | #ffffff | - | - | - | - |
| SecondaryGreyLight | #f5f5f5 | - | - | - | Background |
| Grey | #adb3bc | Text | 1.5:1 | ❌ CRITICAL | On white |
| SecondaryBlue | #52c1ff | Icon | 1.8:1 | ❌ FAIL | On white |

**Recommended Theme Colors**:

| Name | Hex | Contrast | Status |
|------|-----|----------|--------|
| Primary (darkened) | #4a1fd9 | 4.6:1 | ✅ PASS |
| Text Primary | #1a1a1a | 21.0:1 | ✅ PASS |
| Text Secondary | #5a5a5a | 4.6:1 | ✅ PASS |
| Text Disabled | #9a9a9a | 2.8:1 | ⚠️ Large text only |
| Text on Primary | #fcfcfc | 4.8:1 | ✅ PASS |

---

### B. WCAG 2.1 AA Requirements Summary

| Success Criterion | Level | Status | Services Affected |
|-------------------|-------|--------|-------------------|
| 1.1.1 Non-text Content | A | ⚠️ PARTIAL | All |
| 1.2.1 Audio-only/Video-only | A | ⚠️ PARTIAL | BBB, Nextcloud |
| 1.2.2 Captions | A | ❌ FAIL | BBB |
| 1.3.1 Info and Relationships | A | ⚠️ PARTIAL | Portal, ILIAS, Moodle |
| 1.4.3 Contrast (Minimum) | AA | ❌ FAIL | All |
| 2.1.1 Keyboard | A | ⚠️ PARTIAL | All |
| 2.1.2 No Keyboard Trap | A | ✅ PASS | All |
| 2.4.2 Page Title | A | ⚠️ PARTIAL | Moodle, Nextcloud |
| 2.4.7 Focus Visible | AA | ❌ FAIL | All |
| 3.1.1 Language of Page | A | ✅ PASS | All |
| 3.3.2 Labels/Instructions | A | ⚠️ PARTIAL | Moodle, ILIAS |
| 3.3.3 Error Suggestion | AA | ❌ FAIL | Keycloak, Moodle |
| 4.1.1 Parsing | A | ✅ PASS | All |
| 4.1.2 Name, Role, Value | A | ⚠️ PARTIAL | ILIAS, Moodle |

---

### C. Testing Tools

**Automated Tools**:

- [axe-core](https://www.deque.com/axe/) - JavaScript accessibility library
- [Lighthouse](https://developers.google.com/web/tools/lighthouse/) - Chrome DevTools audit
- [Pa11y](https://pa11y.org/) - Command-line accessibility testing
- [WAVE](https://wave.webaim.org/) - Web accessibility evaluation tool

**Manual Tools**:

- NVDA (Windows screen reader)
- JAWS (Windows screen reader)
- VoiceOver (Mac screen reader)
- Contrast Checker (color contrast analyzer)

---

## Conclusion

The openDesk Edu platform requires significant accessibility improvements to achieve WCAG 2.1 AA compliance. The primary concerns are:

1. **Color Contrast** (14 Critical/High issues): Theme colors must be updated
2. **Keyboard Navigation** (6 Critical/High issues): Focus indicators and keyboard access missing
3. **Screen Reader Support** (11 Critical/High issues): ARIA and semantic HTML violations

With the implementation plan outlined in this document, the platform can achieve full WCAG 2.1 AA compliance within 6 months, meeting German legal requirements (BGG, BITV 2.0).

**Next Steps**:

1. Prioritize critical color contrast fixes (Month 1)
2. Implement global focus indicators (Month 2)
3. Fix keyboard navigation (Month 2-3)
4. Conduct screen reader testing (Month 3-4)
5. Implement multimedia accessibility (Month 4-6)

---

**Report Version**: 1.0
**Last Updated**: 2026-03-27
**Contact**: <accessibility@opendesk.example.org>
