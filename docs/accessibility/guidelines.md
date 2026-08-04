<!--
SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

# Accessibility Guidelines for Educators

**Platform**: openDesk Edu v1.1 Foundation
**Target Audience**: Instructors, Course Creators, Content Developers
**Compliance Standard**: WCAG 2.1 Level AA
**Legal Context**: BGG, BITV 2.0 (German accessibility laws)

---

## Table of Contents

1. [Overview](#overview)
2. [Document Accessibility](#document-accessibility)
3. [Video and Multimedia](#video-and-multimedia)
4. [Image Accessibility](#image-accessibility)
5. [Creating Accessible Courses](#creating-accessible-courses)
6. [Testing Your Content](#testing-your-content)
7. [Quick Reference Checklists](#quick-reference-checklists)
8. [Resources and Support](#resources-and-support)

---

## Overview

### Why Accessibility Matters

Accessibility is not just a legal requirement (BGG, BITV 2.0)—it's about creating an inclusive learning environment where all students can succeed, regardless of disability.

**Legal Requirements**:

- **BGG** (Behindertengleichstellungsgesetz): German equality act requires accessible digital content
- **BITV 2.0**: IT accessibility ordinance based on WCAG 2.1 AA
- **EN 301 549**: European accessibility standard

**Benefits**:

- **For Students**: Equal access to learning materials, better comprehension
- **For Educators**: Reach wider audience, improve learning outcomes
- **For Institutions**: Legal compliance, inclusive reputation

**Get Started**: Use the checklists in this document to create accessible course content.

---

## Document Accessibility

### Creating Accessible Word Documents

#### Headings

**Use proper heading styles (Heading 1, Heading 2, etc.)**

✓ **Correct**:

- Use Heading 1 for document title
- Use Heading 2 for main sections
- Use Heading 3 for subsections
- Don't skip levels (H1 → H2 → H3, not H1 → H3)

✗ **Incorrect**:

- Bold or underline text to act as headings (screen readers don't recognize this)
- Skip heading levels (H1 → H3 without H2)
- Use "Heading 1" for elements other than the main title

**How to Apply**:

1. In Word: Home → Styles → Apply Heading 1,Heading 2, etc.
2. In Google Docs: Format → Paragraph styles → Apply Headings
3. In ILIAS: Use the heading dropdown in the page editor

---

#### Lists

**Use proper list formatting (not just dashes)**

✓ **Correct**:

```
Assignment 1: Reading comprehension
- Chapter 1-3
- Quiz due: Friday

Assignment 2: Group presentation
- Form groups by Monday
- Present next week
```

✗ **Incorrect**:

```
Assignment 1: Reading comprehension
• Chapter 1-3
• Quiz due: Friday

Assignment 2: Group presentation
- Form groups by Monday
- Present next week
```

**Problem**: Inconsistent bullet/number formats confuse screen readers

**How to Apply**:

- In Word: Home → Paragraph → Bullets or Numbering
- In Moodle: Use the "Bullet list" or "Numbered list" buttons in the editor

---

#### Links

**Make link text descriptive (not "click here" or "read more")**

✓ **Correct**:

- [Course syllabus](syllabus.pdf)
- [Download the assignment template here](template.docx)
- [Register for the workshop](https://workshop.example.org/register)

✗ **Incorrect**:

- Click [here](syllabus.pdf) for the syllabus
- [Click here](template.docx) to download template
- [Read more](link) about the workshop

**Problem**: Screen reader lists all links ("click here, click here, click here")—no context

**Best Practices**:

- Link text should describe the destination
- Never use URL as link text (e.g., <https://example.org>)
- Avoid opening links in new tabs (unless necessary)—warn user if you do

---

#### Tables

**Use simple table structure with column headers**

✓ **Correct**:
| Week | Topic | Assignment Due |
|------|-------|----------------|
| 1 | Introduction | Reading Quiz |
| 2 | Fundamentals | Problem Set 1 |
| 3 | Advanced Topics | Project Proposal |

**How to Apply**:

1. In Word: Table → Insert Table → Select rows/columns
2. Design → Header Row ➜ Check this box
3. In Moodle: Use the Table insert, check "Header row"

✗ **Incorrect**:

- Merged cells (screen readers can't navigate)
- No header row (screen readers don't know column meaning)
- Empty cells (unclear purpose)

---

#### Images in Documents

**Add alt text to all images**

✓ **Correct**:

```
Alt text: "Bar chart showing 45% A grades, 30% B grades, 15% C grades, 10% D/F"
```

✗ **Incorrect**:

```
Alt text: "chart.png" (filename only)
Alt text: "Image showing grades" (too vague)
Alt text: "" (empty, but image contains information)
```

**How to Add Alt Text**:

- In Word: Right-click image → Format Picture → Alt Text
- In Google Docs: Right-click → Alt text
- In Moodle: Add "Alternative text" field when inserting image

**Decorative Images**: Mark as decorative (alt text="")

```
✓ Decoartive: Dividers, decorative borders, stylistic icons not conveying information
```

---

#### PDF Conversion

**Export to PDF with accessibility tags**

✓ **How to Export**:

1. In Word: File → Save As → PDF → Options ➜ Select "Document structure tags for accessibility"
2. In Google Docs: File → Download → PDF Document (automatic and accessible)
3. Verify: Open in Adobe Acrobat → Tools → Accessibility → Full Check

✗ **Common Issues**:

- Scanned PDFs (images only, not readable)
- Untagged PDFs (screen readers can't navigate)
- Missing bookmarks (hard to navigate long documents)

---

### Creating Accessible Slides (PowerPoint, Google Slides)

#### Slide Structure

**Use unique slide titles**

✓ **Correct**:

- Slide 1: Introduction
- Slide 2: Course Overview
- Slide 3: Week 1 Schedule

✗ **Incorrect**:

- Slide 1: Title
- Slide 2: Title (duplicate titles confuse)

**How to Apply**:

1. In PowerPoint: Home → Layout → Apply layout
2. In Google Slides: Apply title text box to every slide

---

#### Reading Order

**Check reading order of slide content**

✓ **How to Verify**:

1. In PowerPoint: File → Info → Check for Issues → Check Accessibility
2. In Google Slides: Tools → Accessibility → Check accessibility
3. Test with screen reader if possible

✗ **Common Issues**:

- Text boxes out of order
- Content read from top to bottom, not left to right
- Alt text read before image (should be after)

---

#### Excel Spreadsheets

**Use header rows and named ranges**

✓ **Correct**:

- First row: Header row (use "Format as Table")
- Use named ranges for key data sections
- Avoid complex merged cells

**How to Apply**:

1. Insert → Table → Select data ➜ "My table has headers"
2. Accessibility Check (Windows): Review → Check Accessibility

---

## Video and Multimedia

### Captioning Checklist

**All videos must have captions** (BGG/BITV requirement)

✓ **Caption File Format**:

- WebVTT (.vtt) or SRT (.srt)
- Timed text synced with audio
- Include speaker identification
- Include sound effects in brackets [door opens], [laughter]

**Captions Must Include**:

- All spoken dialogue
- Speaker identification (e.g., "Instructor:", "Student:")
- Music descriptions (e.g., [upbeat music fades])
- Sound effects (e.g., [applause], [phone ringing])

---

#### Caption Quick Reference

```
✓ Caption Example:
00:00:05.000 --> 00:00:09.500
Instructor: Welcome to CS101.Today we'll discuss variables.

00:00:10.000 --> 00:00:14.500
[Whiteboard writing sound]
Instructor: Let me write that on the board...
```

---

### Caption Creation Tools

**Free Tools**:

- **YouTube**: Auto-caption (edit for accuracy)
- **Amara**: Manual caption editor (amara.org)
- **Kapwing**: Video editor with caption support

**University Tools**:

- Check with IT department for captioning software
- Some institutions use professional captioning services

**Best Practices**:

- Review auto-generated captions (accuracy ~70-85%)
- Edit for accuracy before publishing
- Include proper punctuation and capitalization
- Verify caption timing (should match speech)

---

### Audio Descriptions

**When are audio descriptions needed?**

✓ **Required If**:

- Video conveys information visually only
- Charts, diagrams, or visual data displayed
- Text on screen not spoken aloud

✓ **Examples Requiring Audio Description**:

- "The bar chart shows 45% A grades" (chart shown, not described)
- "Complete the form in the upper right" (location not spoken)
- "Click the settings icon" (icon location not specified)

**How to Add Audio Descriptions**:

1. **Extended Description**: Provide separate text description (data table, transcript)
2. **Audio Track**: Record narrator describing visual content
3. **Editor Description**: Express in video (speak what's on screen)

**Example**:

```
Video: Shows a bar chart from 0:05-0:15
Audio description: "A bar chart appears on the right side of the screen,
                 showing grade distribution: 45% A grades, 30% B grades,
                 15% C grades, and 10% D or F."
```

---

### Audio Content (Podcasts, Recordings)

**All audio must have transcripts**

✓ **Transcript Requirements**:

- Verbatim text of all spoken content
- Speaker identification
- Timestamp markers (for navigation)
- Downloadable as accessible format (HTML, Word, PDF)

**How to Create**:

1. Use speech-to-text software (e.g., Otter.ai, Whisper)
2. Edit for accuracy
3. Add speaker names and timestamps
4. Save as HTML/Word file alongside audio

---

### Recording Best Practices

**Recording for Accessibility**

✓ **Before Recording**:

- Select quiet location with good acoustics
- Use external microphone (better audio quality than laptop内置)
- Test audio levels (avoid distortion)
- Check lighting (ensure face is visible)

✓ **During Recording**:

- Speak clearly and at moderate pace
- Describe visual content as you go ("I'm now showing...")
- Avoid background noise
- Stay within camera frame

✓ **After Recording**:

- Immediately create captions (while content is fresh)
- Review for accessibility
- Edit out unnecessary pauses/fillers (but not essential content)

---

## Image Accessibility

### Alt Text Guidelines

**Write descriptive alt text for all images**

✓ **Good Alt Text Examples**:

- "Graph showing increasing student enrollment from 2020-2024"
- "Professor Smith lecturing on quantum mechanics"
- "Screenshot of Moodle discussion board interface"
- "Flowchart: Research process steps: 1. Question → 2. Search → 3. Evaluate → 4. Document"

✗ **Bad Alt Text Examples**:

- "image1.png" (filename)
- "Chart" (too vague)
- "A picture" (no information)
- "" (empty, but image has info)

---

#### Complex Images (Charts, Diagrams)

**Provide extended descriptions or alternatives**

✓ **Approaches**:

**1. Data Tables** (for charts):

```
Alt text: "Line graph showing exam scores from Week 1 to Week 10"
Long description: Table in alt text or below image:
Week | Average Score
1 | 75.5
2 | 78.0
3 | 82.5
...
10 | 92.0
```

**2. Text Description** (for diagrams):

```
Alt text: "Flowchart of research process"
Longdesc (link): Full text description of process steps
```

**3. Simplified Versions** (for complex diagrams):

```
Main image: Complex system architecture
Alt image: Simplified version with key components highlighted
```

---

#### Charts and Graphs

**Ensure charts are accessible**

✓ **Accessibility Checklist**:

- [ ] Alt text describes the trend (e.g., "Line graph showing upward trend")
- [ ] Data table provided (for screen reader users)
- [ ] Colors have sufficient contrast (3:1 minimum)
- [ ] Lines/bars are thick enough to see
- [ ] Text labels are legible (14pt+ recommended)

**Example Accessible Chart**:

```html
<figure>
  <img src="enrollment-chart.png" alt="Line graph showing 45% increase in student enrollment from 2020-2024">
  <figcaption>Figure 1: Student enrollment trends</figcaption>
  <table>
    <caption>Enrollment data 2020-2024</caption>
    <tr><th>Year</th><th>Students</th></tr>
    <tr><td>2020</td><td>500</td></tr>
    <tr><td>2021</td><td>600</td></tr>
    <tr><td>2022</td><td>700</td></tr>
    <tr><td>2023</td><td>725</td></tr>
    <tr><td>2024</td><td>725</td></tr>
  </table>
</figure>
```

---

#### Text in Images

**Avoid text in images (screen readers can't read)**

✓ **Preferred Approaches**:

- Use HTML text with CSS styling
- Excel for spreadsheets (PDF export)
- Markdown/code blocks for code

✗ **Problematic**:

```
Image of typed exam questions (screen reader can't read)
Screenshot of code (can't copy-paste)
Scanned PDF of syllabus (not searchable)
```

✓ **Solution**:

- Type content directly into page editor
- Provide text alternative or transcript
- OCR scanned documents (inaccurate; don't rely on it)

---

## Creating Accessible Courses

### Moodle Course Setup

#### Course Structure

**Organize course with clear sections and headings**

✓ **Moodle Best Practices**:

- Use Course Navigation (sidebar) for weekly sections
- Consistent naming: "Week 1", "Week 2", etc.
- Add section descriptions in "Edit settings"
- Enable accessibility plugin (if available)

✗ **Common Mistakes**:

- Disorganized file list (no structure)
- Generic section names ("Section 1", "Section 2")
- No context for files (file only, no description)

**How to Apply**:

1. Course administration → Edit settings → Section names
2. Turn editing on → Add summary/description to each section
3. Organize files with clear naming (e.g., "Week1_Notes.pdf" not "doc1.pdf")

---

#### Moodle Activities

**Label all activities and resources**

✓ **Correct**:

- "Quiz 1: Introduction to Variables (covers Chapters 1-3)"
- "Discussion Forum: Week 1 Reading Reflection due Friday"

✗ **Incorrect**:

- "Quiz 1" ( vague title)
- "Discussion" (no topic)
- "Download" (activity type only)

**How to Apply**:

1. Add/edit activity → "Name" field
2. Use descriptive, activity-type specific titles
3. Add description field (shown on page)

---

#### Files in Moodle

**Provide accessible file formats**

✓ **Preferred Formats**:

- HTML pages (most accessible: digital text, can be enlarged)
- PDF (accessible if properly tagged: use Adobe Acrobat PRO)
- Word documents (use heading styles, alt text)

✗ **Avoid or Provide Alternatives**:

- Scanned PDFs (not readable by screen readers)
- Image-only files (JPG charts: add alt text + data table)
- Unconverted PowerPoint (text in images)

**File Checklist**:

- [ ] File is in accessible format (HTML, tagged PDF, Word)
- [ ] File has descriptive filename (not "doc1.pdf")
- [ ] File description includes content summary
- [ ] Large files broken into smaller parts (if appropriate)

---

### ILIAS Course Setup

#### Learning Modules

**Use structured learning modules**

✓ **ILIAS Best Practices**:

- Add chapter headings (Heading 1, Heading 2)
- Include descriptions for media
- Use table of contents for navigation
- Test with ILIAS accessibility mode

**How to Apply**:

1. Learning Module → Add page → Use heading dropdown
2. Add description to images/media
3. Break long content into multiple pages

---

#### ILIAS Resources

**Organize resources with clear structure**

✓ **Best Practices**:

- Folders by week/topic
- Descriptive file names
- Add metadata (description)
- Provide accessible formats (PDF, HTML)

---

### General Course Design

#### Color Use

**Ensure color contrast for all text**

✓ **WCAG 2.1 AA Requirements**:

- Normal text (under 18pt): 4.5:1 contrast minimum
- Large text (18pt+ or bold 14pt+): 3:1 contrast minimum
- UI components (buttons, icons): 3:1 contrast minimum

**Color Contrast checker**: Use axe-devtools or WebAIM Contrast Checker

✓ **Accessible Color Pairs**:

- Black (#000000) on white (#ffffff): 21:1 (excellent)
- Dark blue (#1a1a8c) on white (#ffffff): 11.0:1 (good)
- Black (#000000) on light gray (#f5f5f5): 19.6:1 (good)

✗ **Avoid**:

- Light gray (#adb3bc) on white (#ffffff): 1.5:1 (FAILS)
- Yellow (#ffc700) on white (#ffffff): 1.9:1 (FAILS)

**How to Apply**:

1. Test in Word/Google Docs (color contrast check)
2. Use bold or larger text if using lighter colors
3. Verify focus indicators are visible

---

#### Font Guidelines

**Use legible fonts and sizes**

✓ **Recommended Fonts**:

- Sans-serif fonts: Arial, Helvetica, Verdana, Calibri
- Serif fonts: Times New Roman, Georgia
- Font size: at least 16px (12pt) for body text
- Headings: 18pt+ (H1), 16pt+ (H2), 14pt+ (H3)

✓ **WCAG Requirements (2.1 AA)**:

- Line height: at least 1.5x font size (body)
- Letter spacing: at least 0.12x font size
- Word spacing: at least 0.16x font size
- Paragraph spacing: at least 2x font size

**How to Apply**:

- Default size usually meets requirements (16px)
- Check student view (HTML editor) for legibility
- Test on mobile devices

---

## Testing Your Content

### Quick Accessibility Tests

#### Microsoft Office Check

✓ **Word, PowerPoint, Excel**:

1. File → Info → Check for Issues → Check Accessibility
2. Review warnings and fix issues
3. Re-check until no warnings

**Common Office Issues**:

- [ ] Images missing alt text
- [ ] Missing document title (not just "Document1")
- [ ] No table headers
- [ ] PDF export untagged (for Office 365, use "Save as accessible PDF")

---

#### Google Workspace Check

✓ **Docs, Slides, Sheets**:

1. Tools → Accessibility settings → Check accessibility
2. Review warnings
3. Use "Make accessible" suggestions (for Slides)

**Common Issues**:

- [ ] Images missing alt text
- [ ] Duplicate slide titles
- [ ] Low contrast text

---

#### LMS Platform Check

✓ **Moodle**:

1. Enable accessibility checklist plugin (if available)
2. Preview course as student
3. Test with screen reader (NVDA, JAWS, VoiceOver)

✓ **ILIAS**:

1. Enable accessibility mode (user settings)
2. Test learning module navigation
3. Verify alt text displays

---

#### Web-Based Testing Tools

✓ **Free Tools**:

- **axe DevTools** (Chrome/Firefox extension): Automated WCAG checker
- **WAVE**: Web accessibility evaluation tool (wave.webaim.org)
- **Lighthouse**: Chrome DevTools audit → Accessibility

**How to Useaxe**:

1. Install axe DevTools extension
2. Open course page in browser
3. Open DevTools (F12) → axe DevTools → Scan page
4. Fix critical issues (red), high issues (orange)

---

### Manual Testing Checklist

#### Keyboard Navigation Test

✓ **Test Steps**:

1. Unplug mouse (use only keyboard)
2. Tab through all interactive elements (links, buttons, forms)
3. Press Enter/Space to activate

**What to Check**:

- [ ] All interactive elements reachable with keyboard
- [ ] Focus indicator visible on each element
- [ ] No keyboard traps (can't escape modal)
- [ ] Focus order follows visual layout

**Failures to Fix**:

- Can't reach element with tab → contact IT/platform team
- Invisible focus indicator → check settings (sometimes hidden)
- Keyboard trap in popover → close with ESC key

---

#### Screen Reader Test

✓ **Screen Readers**:

- Windows: NVDA (free), JAWS (paid)
- Mac: VoiceOver (built-in)

**Test Steps**:

1. Open screen reader software
2. Navigate course page
3. Use Tab/Arrow keys to move
4. Listen for announcements

**What to Check**:

- [ ] Page structure announced (headings, landmarks)
- [ ] Links announced with text
- [ ] Headings announced as headings
- [ ] Images announced with alt text
- [ ] Forms announced with labels
- [ ] Dynamic content announced (alerts, notifications)

**Common Screen Reader Issues**:

- [ ] "Heading 1" announced as "blank" (empty heading, remove)
- [ ] "Link" with no text → add link text
- [ ] "Image" with no alt text → add alt text
- [ ] Heading structure混乱 (fix heading levels)

---

#### Color Contrast Test

✓ **Testing Tools**:

- **axe DevTools**: Shows contrast ratios
- **WebAIM Contrast Checker**: manual check (contrastchecker.com)
- **Color Oracle**: Color blindness simulation

**Test Steps**:

1. Install axe DevTools extension
2. Open page content
3. Check "Contrast violations" tab
4. Fix elements listed (red = critical, orange = high)

**Contrast Requirements**:

- Normal text: 4.5:1 minimum
- Large text (18pt+): 3:1 minimum
- UI components (buttons): 3:1 minimum

**Fixing Issues**:

- Low contrast text → darken text or lighten background
- Low contrast icon → use darker icon or add visible border
- Verify with color blindness simulation

---

## Quick Reference Checklists

### Document Checklist (Word, PDF)

#### Before Publishing

- [ ] Heading styles applied (H1, H2, H3)
- [ ] Lists formatted correctly (bullets/numbers)
- [ ] Links descriptive (not "click here")
- [ ] Tables have header row
- [ ] Alt text on all images
- [ ] Decorative images marked decorative
- [ ] Color contrast verified (4.5:1 text)
- [ ] PDF exported with accessibility tags
- [ ] Accessibility check shows no errors

---

### Presentation Checklist (PowerPoint, Google Slides)

#### Before Recording/()

- [ ] Each slide has unique title
- [ ] Reading order verified ( проверки в PowerPoint)
- [ ] Alt text on all images
- [ ] Charts have data tables
- [ ] Video/audio has captions
- [ ] Color contrast verified
- [ ] Font size ≥18pt for text
- [ ] Slide notes provided (optional)

---

### Video Checklist

#### Before Uploading

- [ ] Captions created (VTT/SubRip)
- [ ] Captions reviewed for accuracy
- [ ] Speaker identification included
- [ ] Audio quality clear (no background noise)
- [ ] Audio description (if showing visual-only information)
- [ ] Transcript provided (HTML/Word)
- [ ] Video player supports captions

---

### Course Content Checklist

#### Before Publishing Course

- [ ] Course structure clear (weekly sections)
- [ ] All files accessible (HTML/tagged PDF)
- [ ] Images have alt text
- [ ] Charts have data tables
- [ ] Videos have captions
- [ ] Forms have labels
- [ ] Color contrast meets 4.5:1
- [ ] Keyboard navigation tested
- [ ] Screen reader tested (if possible)

---

## Resources and Support

### University Resources

**Accessibility Office**:

- Contact: your institution's accessibility/disability office
- Services: Captioning, document conversion, assistive technology

**IT Help Desk**:

- Contact: your IT department
- Services: Platform accessibility issues, software support

**Accessibility Statement**:

- URL: [Platform Accessibility Statement](/accessibility)
- Contact: <accessibility@example.org>

---

### External Resources

**WCAG 2.1 AA Documentation**:

- [WCAG 2.1 Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/)
- [WCAG 2.1 Understanding](https://www.w3.org/WAI/WCAG21/understanding/)

**Accessibility Tools**:

- [axe DevTools](https://www.deque.com/axe/devtools/) (Chrome extension)
- [WAVE](https://wave.webaim.org/) (Web evaluation)
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/) (Color contrast)

**Screen Readers**:

- [NVDA](https://www.nvaccess.org/) (Windows, free)
- [JAWS](https://www.freedomscientific.com/products/software/jaws/) (Windows, paid)
- [VoiceOver](https://www.apple.com/accessibility/voiceover/) (Mac, built-in)

**Captioning Tools**:

- [Amara](https://amara.org/) (Manual editing)
- [YouTube Auto-Captions](https://support.google.com/youtube/answer/2734796) (Auto, needs editing)

---

### Training and Support

**Accessibility Training**:

- Check your institution for accessibility workshops
- Online: [W3C WAI Web Accessibility Training](https://www.w3.org/WAI/fundamentals/)
- MOOCs: Accessible digital learning courses (search for "Web accessibility MOOC")

**Getting Help**:

- Platform-specific issues: IT Help Desk
- Content-creation questions: Accessibility Office
- WCAG 2.1 requirements: Refer to WCAG documentation or accessibility office

---

### Common Myths

❌ **Myth**: Accessibility is only for blind students
✓ **Reality**: Accessibility helps everyone (students using mobile, non-native speakers, low vision, etc.)

❌ **Myth**: Accessibility means ugly designs
✓ **Reality**: Accessible design is often better design (clearer, more usable for everyone)

❌ **Myth**: Alt text slows down screen reader users
✓ **Reality**: Good alt text enhances navigation and comprehension

❌ **Myth**: Making content accessible takes too long
✓ **Reality**: With practice, accessibility becomes part of standard process

---

## Summary

**Key Takeaways**:

1. **Structure matters**: Use headings, lists, tables correctly
2. **Describe images**: Alt text for ALL images
3. **Caption videos**: All multimedia needs captions/transcripts
4. **Check contrast**: 4.5:1 for normal text, 3:1 for large text
5. **Test tools**: Use Microsoft Office checkers, axe DevTools
6. **Test manually**: Keyboard navigation, screen reader (if available)
7. **Start early**: Build accessibility into workflow, not as afterthought

**Quick Start Checklist** (for new content):

- [ ] Document: Heading styles, Alt text, Lists formatted
- [ ] Images: Alt text (descriptive), Decorative marked
- [ ] Video: Captions, Transcript
- [ ] Color: Contrast verified (4.5:1 text)
- [ ] Test: Office checker/Google checker,axe scan

**Remember**: Accessibility is not just legal compliance—it's about creating an inclusive learning environment for all students. Start small, build habits, and improve over time.

---

**Document Version**: 1.0
**Last Updated**: 2026-03-27
**Next Review**: 2026-09-27 (6 months)
