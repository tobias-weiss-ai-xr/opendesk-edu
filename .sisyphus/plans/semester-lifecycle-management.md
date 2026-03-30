# Semester Lifecycle Management — Implementation Plan

## 1. TASK OVERVIEW

Implement **Semester Lifecycle Management** — enabling openDesk Edu to automate course provisioning, enrollment, role assignment, and archival according to the university semester cycle (Wintersemester/Sommersemester). This is the #2 priority feature in v1.1 — Foundation.

**Source**: `ROADMAP.md` lines 52-61 (v1.1 — Foundation)

### Requirements (from ROADMAP.md)
- [ ] Course provisioning API (create/archive courses per semester)
- [ ] Role-based access control tied to semester enrollment (instructor, student, tutor)
- [ ] Automated course archival at semester end
- [ ] Integration hook for campus management systems (HIS/LSF)

---

## 2. SCOPE & DELIMITATIONS

### In Scope
- Semester calendar configuration (WS/SS dates, start/end)
- Course provisioning API for ILIAS, Moodle, OpenCloud/Nextcloud, BBB
- Role synchronization based on semester enrollment status
- Automated course archival workflow (freeze access, preserve data)
- Campus management system integration hooks (HISinOne, LSF, Marvin)
- Cron-based automation for semester transitions
- Audit logging for all lifecycle operations
- Bilingual documentation (German/English)

### Out of Scope
- Direct HISinOne API implementation (deferred to v1.5)
- Real-time enrollment synchronization (deferred to v1.5)
- Student data import from LDAP/AD (deferred to v1.5)
- Grade/exam data integration (deferred to v1.5)
- Custom campus management connector development

---

## 3. ARCHITECTURE

### 3.1 Component Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           Semester Lifecycle Manager                             │
│                                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────────┐    │
│  │ Semester Config │    │ Course Provision│    │ Role Sync Engine        │    │
│  │ (Helm values)   │    │ API (REST)      │    │ (Keycloak + LMS)        │    │
│  └────────┬────────┘    └────────┬────────┘    └────────────┬────────────┘    │
│           │                      │                          │                 │
│           └──────────────────────┴──────────────────────────┘                 │
│                                      │                                         │
│  ┌───────────────────────────────────┴───────────────────────────────────┐    │
│  │                        Automation Layer (CronJobs)                     │    │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────┐   │    │
│  │  │ Semester Start  │  │ Mid-Semester    │  │ Semester End        │   │    │
│  │  │ Job             │  │ Check Job       │  │ Archival Job        │   │    │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────┘   │    │
│  └──────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────┬─────────────────────────────────┘
                                              │
                    ┌─────────────────────────┼─────────────────────────┐
                    │                         │                         │
                    ▼                         ▼                         ▼
┌───────────────────────────┐ ┌───────────────────────────┐ ┌───────────────────────────┐
│  ILIAS (LMS)              │ │  Moodle (LMS)             │ │  OpenCloud/Nextcloud      │
│  - Course creation        │ │  - Course creation        │ │  - Course file shares     │
│  - User enrollment        │ │  - User enrollment        │ │  - Group permissions      │
│  - Role assignment        │ │  - Role assignment        │ │  - Archive on semester end│
│  - Course archival        │ │  - Course archival        │ │                           │
└───────────────────────────┘ └───────────────────────────┘ └───────────────────────────┘

                    ┌───────────────────────────────────────────────────────┐
                    │                    Campus Management                  │
                    │  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐  │
                    │  │ HISinOne    │  │ LSF         │  │ Marvin       │  │
                    │  │ (Phase 2)   │  │ (Phase 2)   │  │ (Phase 2)    │  │
                    │  └─────────────┘  └─────────────┘  └──────────────┘  │
                    └───────────────────────────────────────────────────────┘
```

### 3.2 Semester Calendar Model

```yaml
# Example: German university semester calendar
semesters:
  current:
    name: "WS25/26"
    type: "wintersemester"
    start_date: "2025-10-01"
    end_date: "2026-03-31"
    teaching_period:
      start: "2025-10-15"
      end: "2026-02-28"
    exam_period:
      start: "2026-03-01"
      end: "2026-03-31"
    enrollment_period:
      start: "2025-07-01"
      end: "2025-09-30"
      re_enrollment:
        start: "2025-09-01"
        end: "2025-09-30"
    archival_deadline: "2026-04-15"

  next:
    name: "SS26"
    type: "sommersemester"
    start_date: "2026-04-01"
    end_date: "2026-09-30"
    # ... same structure
```

### 3.3 Course Lifecycle States

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│    DRAFT        │────►│  ACTIVE         │────►│  ARCHIVED       │
│                 │     │                 │     │                 │
│ - Course created│     │ - Teaching      │     │ - Access frozen │
│ - No students   │     │ - Full access   │     │ - Read-only     │
│ - Instructor    │     │ - Enrollments   │     │ - Data preserved│
└─────────────────┘     └─────────────────┘     └─────────────────┘
        ▲                       │                       │
        │                       │                       │
        └───────────────────────┴───────────────────────┘
                                │
                    ┌───────────┴───────────┐
                    │  Rollback/Reopen      │
                    │  (Admin only)         │
                    └───────────────────────┘
```

### 3.4 Role Mapping Model

| HISinOne Role | Keycloak Role | ILIAS Role | Moodle Role | Access Level |
|:--------------|:--------------|:-----------|:------------|:-------------|
| `student` | `student` | `Student` | `student` | Read + submit |
| `tutor` | `tutor` | `Tutor` | `editingteacher` | Teach + grade |
| `lecturer` | `instructor` | `Dozent` | `editingteacher` | Full control |
| `auditor` | `auditor` | `Hörer` | `guest` | Read-only |
| `external` | `affiliate` | `Externe` | `guest` | Limited access |

---

## 4. IMPLEMENTATION DETAILS

### 4.1 Semester Configuration (Helm Values)

```yaml
# helmfile/environments/default/semester-lifecycle.yaml.gotmpl

semester:
  enabled: true
  
  # Current semester definition
  current:
    name: "WS25/26"
    type: "wintersemester"  # wintersemester | sommersemester
    start_date: "2025-10-01"
    end_date: "2026-03-31"
    
    # Phase dates
    phases:
      enrollment:
        start: "2025-07-01"
        end: "2025-09-30"
      teaching:
        start: "2025-10-15"
        end: "2026-02-28"
      exam:
        start: "2026-03-01"
        end: "2026-03-31"
      archival:
        deadline: "2026-04-15"
  
  # Automation settings
  automation:
    enabled: true
    timezone: "Europe/Berlin"
    
    # Cron schedules for lifecycle jobs
    cron:
      semester_start: "0 6 1 {{ .Values.semester.current.type }} *"  # 1st day, 6 AM
      mid_semester_check: "0 9 15 * *"  # 15th of each month, 9 AM
      semester_end: "0 6 1 {{ .Values.semester.current.type | add 6 }} *"  # 6 months later
      archival_cleanup: "0 2 1 4 *"  # April 1st, 2 AM (after archival deadline)
  
  # Course provisioning defaults
  provisioning:
    default_category: "courses"
    course_prefix: "{{ .Values.semester.current.name }}-"
    auto_archive: true
    archive_retention_years: 5
    
  # Role synchronization
  roles:
    sync_on_enrollment_change: true
    sync_interval_minutes: 15
    role_mappings:
      - campus_role: "student"
        keycloak_role: "student"
        lms_role: "student"
      - campus_role: "tutor"
        keycloak_role: "tutor"
        lms_role: "tutor"
      - campus_role: "lecturer"
        keycloak_role: "instructor"
        lms_role: "instructor"
```

### 4.2 Course Provisioning API

```python
# scripts/semester-provisioning/course_api.py

from dataclasses import dataclass
from datetime import datetime
from typing import List, Optional
from enum import Enum

class CourseStatus(Enum):
    DRAFT = "draft"
    ACTIVE = "active"
    ARCHIVED = "archived"

class SemesterType(Enum):
    WINTERSEMESTER = "wintersemester"
    SOMMERSEMESTER = "sommersemester"

@dataclass
class Semester:
    name: str
    type: SemesterType
    start_date: datetime
    end_date: datetime
    phases: dict

@dataclass
class Course:
    id: str
    title: str
    semester: str
    instructor_ids: List[str]
    student_ids: List[str]
    status: CourseStatus
    created_at: datetime
    archived_at: Optional[datetime] = None

class CourseProvisioningAPI:
    """
    REST API for course lifecycle management.
    
    Endpoints:
    - POST /api/v1/courses - Create new course
    - GET /api/v1/courses - List courses (filter by semester, status)
    - GET /api/v1/courses/{id} - Get course details
    - PUT /api/v1/courses/{id} - Update course
    - DELETE /api/v1/courses/{id} - Soft delete (archive)
    - POST /api/v1/courses/{id}/archive - Archive course
    - POST /api/v1/courses/{id}/restore - Restore archived course
    - POST /api/v1/semester/transition - Trigger semester transition
    """
    
    def __init__(self, config: dict):
        self.config = config
        self.ilias_client = ILIASClient(config['ilias'])
        self.moodle_client = MoodleClient(config['moodle'])
        self.keycloak_client = KeycloakClient(config['keycloak'])
    
    def create_course(
        self,
        title: str,
        semester: str,
        instructor_ids: List[str],
        student_ids: List[str] = None,
        lms_platform: str = "ilias"
    ) -> Course:
        """
        Provision a new course on the specified LMS platform.
        
        Args:
            title: Course title
            semester: Semester identifier (e.g., "WS25/26")
            instructor_ids: List of Keycloak user IDs for instructors
            student_ids: Optional list of Keycloak user IDs for students
            lms_platform: Target platform ("ilias" or "moodle")
        
        Returns:
            Course object with generated ID and platform-specific IDs
        """
        course_id = f"{semester}-{title.lower().replace(' ', '-')}"
        
        # Create course on LMS
        if lms_platform == "ilias":
            ilias_course_id = self.ilias_client.create_course(
                title=title,
                category=self.config['provisioning']['default_category'],
                description=f"Course for {semester}"
            )
        elif lms_platform == "moodle":
            ilias_course_id = self.moodle_client.create_course(
                short_name=course_id,
                fullname=title,
                category_id=self.config['provisioning']['default_category']
            )
        
        # Assign instructors
        for user_id in instructor_ids:
            self.assign_role(user_id, course_id, "instructor", lms_platform)
        
        # Enroll students if provided
        if student_ids:
            for user_id in student_ids:
                self.assign_role(user_id, course_id, "student", lms_platform)
        
        # Create course record in database
        course = Course(
            id=course_id,
            title=title,
            semester=semester,
            instructor_ids=instructor_ids,
            student_ids=student_ids or [],
            status=CourseStatus.ACTIVE,
            created_at=datetime.utcnow()
        )
        
        self._save_course(course)
        
        # Audit log
        self._audit_log("course_created", {
            "course_id": course_id,
            "title": title,
            "semester": semester,
            "instructor_count": len(instructor_ids),
            "student_count": len(student_ids or [])
        })
        
        return course
    
    def archive_course(self, course_id: str) -> Course:
        """
        Archive a course at semester end.
        
        Actions:
        1. Freeze all enrollments (no new students)
        2. Revoke write access for students
        3. Preserve all data (read-only access)
        4. Create archive snapshot
        5. Update course status
        
        Args:
            course_id: Course identifier
        
        Returns:
            Updated Course object
        """
        course = self._get_course(course_id)
        
        # Freeze enrollments
        self._freeze_enrollments(course_id)
        
        # Revoke student write access
        self._revoke_student_access(course_id)
        
        # Create archive snapshot
        self._create_archive_snapshot(course_id)
        
        # Update course status
        course.status = CourseStatus.ARCHIVED
        course.archived_at = datetime.utcnow()
        self._save_course(course)
        
        # Audit log
        self._audit_log("course_archived", {
            "course_id": course_id,
            "title": course.title,
            "semester": course.semester,
            "archived_at": course.archived_at.isoformat()
        })
        
        return course
    
    def semester_transition(self, old_semester: str, new_semester: str) -> dict:
        """
        Execute full semester transition workflow.
        
        Workflow:
        1. Archive all active courses from old semester
        2. Create new semester configuration
        3. Provision new courses (if automated provisioning enabled)
        4. Sync enrollments from campus management
        5. Activate new semester courses
        
        Args:
            old_semester: Previous semester identifier
            new_semester: New semester identifier
        
        Returns:
            Transition report with statistics
        """
        report = {
            "old_semester": old_semester,
            "new_semester": new_semester,
            "archived_courses": [],
            "created_courses": [],
            "synced_enrollments": 0,
            "errors": []
        }
        
        # Step 1: Archive old semester courses
        old_courses = self._list_courses(semester=old_semester, status=CourseStatus.ACTIVE)
        for course in old_courses:
            try:
                self.archive_course(course.id)
                report["archived_courses"].append(course.id)
            except Exception as e:
                report["errors"].append({
                    "course_id": course.id,
                    "error": str(e)
                })
        
        # Step 2: Create new semester configuration
        self._create_semester_config(new_semester)
        
        # Step 3: Provision new courses (if automated)
        if self.config['automation']['auto_provision']:
            # This would integrate with HISinOne in v1.5
            # For now, placeholder
            pass
        
        # Step 4: Sync enrollments (placeholder for v1.5)
        # synced = self._sync_enrollments(new_semester)
        # report["synced_enrollments"] = synced
        
        # Step 5: Activate new courses
        new_courses = self._list_courses(semester=new_semester, status=CourseStatus.DRAFT)
        for course in new_courses:
            course.status = CourseStatus.ACTIVE
            self._save_course(course)
        
        return report
```

### 4.3 Role Synchronization Engine

```python
# scripts/semester-provisioning/role_sync.py

from dataclasses import dataclass
from typing import List, Dict
import logging

logger = logging.getLogger(__name__)

@dataclass
class EnrollmentChange:
    """Represents a single enrollment change event."""
    user_id: str
    course_id: str
    action: str  # "add" | "remove" | "role_change"
    old_role: str = None
    new_role: str = None
    timestamp: str = None

class RoleSyncEngine:
    """
    Synchronizes user roles across Keycloak and all LMS platforms.
    
    Triggers:
    - Manual API calls (immediate sync)
    - Cron job (periodic sync every 15 minutes)
    - Campus management webhooks (real-time, v1.5)
    
    Strategy:
    1. Fetch current enrollments from all LMS platforms
    2. Fetch desired enrollments from campus management (or database)
    3. Compute delta (additions, removals, role changes)
    4. Apply changes to both Keycloak and LMS platforms
    5. Log all changes for audit trail
    """
    
    def __init__(self, config: dict):
        self.config = config
        self.keycloak = KeycloakClient(config['keycloak'])
        self.ilias = ILIASClient(config['ilias'])
        self.moodle = MoodleClient(config['moodle'])
    
    def sync_all(self, semester: str = None) -> dict:
        """
        Full synchronization for all courses in a semester.
        
        Args:
            semester: Optional semester filter (defaults to current)
        
        Returns:
            Sync report with statistics
        """
        if semester is None:
            semester = self._get_current_semester()
        
        report = {
            "semester": semester,
            "courses_processed": 0,
            "enrollments_added": 0,
            "enrollments_removed": 0,
            "roles_changed": 0,
            "errors": []
        }
        
        # Get all active courses for semester
        courses = self._get_active_courses(semester)
        
        for course in courses:
            try:
                result = self.sync_course(course.id)
                report["courses_processed"] += 1
                report["enrollments_added"] += result["added"]
                report["enrollments_removed"] += result["removed"]
                report["roles_changed"] += result["changed"]
            except Exception as e:
                report["errors"].append({
                    "course_id": course.id,
                    "error": str(e)
                })
        
        return report
    
    def sync_course(self, course_id: str) -> dict:
        """
        Synchronize enrollments for a single course.
        
        Args:
            course_id: Course identifier
        
        Returns:
            Sync result with counts
        """
        result = {"added": 0, "removed": 0, "changed": 0}
        
        # Get desired enrollments (from database or campus management)
        desired = self._get_desired_enrollments(course_id)
        
        # Get current enrollments from LMS
        current_ilias = self.ilias.get_enrollments(course_id) if self._course_on_ilias(course_id) else {}
        current_moodle = self.moodle.get_enrollments(course_id) if self._course_on_moodle(course_id) else {}
        
        # Compute deltas
        for user_id, role in desired.items():
            # Check if user should be enrolled
            enrolled_ilias = user_id in current_ilias
            enrolled_moodle = user_id in current_moodle
            
            # Add to platforms where missing
            if not enrolled_ilias and self._course_on_ilias(course_id):
                self.ilias.enroll_user(user_id, course_id, role)
                result["added"] += 1
                self._audit_enrollment_change(course_id, user_id, "add", role)
            
            if not enrolled_moodle and self._course_on_moodle(course_id):
                self.moodle.enroll_user(user_id, course_id, role)
                result["added"] += 1
                self._audit_enrollment_change(course_id, user_id, "add", role)
            
            # Update role if changed
            if enrolled_ilias and role != current_ilias.get(user_id):
                self.ilias.update_role(user_id, course_id, role)
                result["changed"] += 1
                self._audit_enrollment_change(course_id, user_id, "role_change", role, current_ilias.get(user_id))
            
            if enrolled_moodle and role != current_moodle.get(user_id):
                self.moodle.update_role(user_id, course_id, role)
                result["changed"] += 1
                self._audit_enrollment_change(course_id, user_id, "role_change", role, current_moodle.get(user_id))
        
        # Remove users no longer enrolled
        all_current_users = set(current_ilias.keys()) | set(current_moodle.keys())
        desired_users = set(desired.keys())
        
        for user_id in all_current_users - desired_users:
            if self._course_on_ilias(course_id) and user_id in current_ilias:
                self.ilias.unenroll_user(user_id, course_id)
                result["removed"] += 1
                self._audit_enrollment_change(course_id, user_id, "remove", None, current_ilias.get(user_id))
            
            if self._course_on_moodle(course_id) and user_id in current_moodle:
                self.moodle.unenroll_user(user_id, course_id)
                result["removed"] += 1
                self._audit_enrollment_change(course_id, user_id, "remove", None, current_moodle.get(user_id))
        
        return result
    
    def _get_desired_enrollments(self, course_id: str) -> Dict[str, str]:
        """
        Fetch desired enrollments from database or campus management.
        
        In v1.1: Read from local database (manual provisioning)
        In v1.5: Query HISinOne via proxy
        """
        # Placeholder - would query database in v1.1
        # Would query HISinOne in v1.5
        return {}
```

### 4.4 Automation CronJobs

```yaml
# helmfile/apps/semester-provisioning/templates/cronjobs.yaml

apiVersion: batch/v1
kind: CronJob
metadata:
  name: semester-start-job
  namespace: {{ .Values.namespace }}
spec:
  schedule: "{{ .Values.semester.automation.cron.semester_start }}"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: semester-provisioning
            image: {{ .Values.images.semester_provisioning }}
            command:
            - /app/semester-provisioning
            - transition
            - --old-semester={{ .Values.semester.previous.name }}
            - --new-semester={{ .Values.semester.current.name }}
            env:
            - name: SEMESTER_CONFIG
              valueFrom:
                configMapKeyRef:
                  name: semester-config
                  key: config.yaml
            - name: LOG_LEVEL
              value: "INFO"
          restartPolicy: OnFailure
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: role-sync-job
  namespace: {{ .Values.namespace }}
spec:
  schedule: "*/15 * * * *"  # Every 15 minutes
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 1
  failedJobsHistoryLimit: 3
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: semester-provisioning
            image: {{ .Values.images.semester_provisioning }}
            command:
            - /app/semester-provisioning
            - sync-roles
            - --semester={{ .Values.semester.current.name }}
            env:
            - name: SEMESTER_CONFIG
              valueFrom:
                configMapKeyRef:
                  name: semester-config
                  key: config.yaml
          restartPolicy: OnFailure
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: semester-end-job
  namespace: {{ .Values.namespace }}
spec:
  schedule: "{{ .Values.semester.automation.cron.semester_end }}"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: semester-provisioning
            image: {{ .Values.images.semester_provisioning }}
            command:
            - /app/semester-provisioning
            - archive-semester
            - --semester={{ .Values.semester.current.name }}
            env:
            - name: SEMESTER_CONFIG
              valueFrom:
                configMapKeyRef:
                  name: semester-config
                  key: config.yaml
          restartPolicy: OnFailure
```

---

## 5. FILE STRUCTURE

```
scripts/
└── semester-provisioning/
    ├── __init__.py
    ├── course_api.py                 # Course provisioning REST API
    ├── role_sync.py                  # Role synchronization engine
    ├── semester_manager.py           # Semester lifecycle management
    ├── archive.py                    # Course archival logic
    ├── cli.py                        # Command-line interface
    ├── config.py                     # Configuration loading
    ├── database.py                   # SQLite/PostgreSQL models
    └── README.md                     # Usage documentation

helmfile/
└── apps/
    └── semester-provisioning/
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── deployment.yaml       # API deployment
            ├── service.yaml          # REST API service
            ├── configmap.yaml        # Configuration
            ├── cronjobs.yaml         # Automation jobs
            └── rbac.yaml             # Service account permissions

docs/
├── semester-lifecycle.md             # User guide (bilingual)
├── course-provisioning-api.md        # API documentation
└── semester-automation-guide.md      # Automation setup

tests/
└── integration/
    └── test_semester_lifecycle.py    # End-to-end tests
```

---

## 6. TEST STRATEGY

### 6.1 Unit Tests

- Test course creation with various parameters
- Test role mapping logic (campus role → LMS role)
- Test course archival workflow
- Test semester transition logic
- Test cron schedule parsing

### 6.2 Integration Tests

- Test course provisioning on ILIAS
- Test course provisioning on Moodle
- Test role synchronization across platforms
- Test archival and restore workflow
- Test semester transition end-to-end

### 6.3 Test Cases

```python
# tests/integration/test_semester_lifecycle.py

def test_course_creation():
    """Test creating a new course."""
    api = CourseProvisioningAPI(config)
    course = api.create_course(
        title="Einführung in Informatik",
        semester="WS25/26",
        instructor_ids=["user-123"],
        student_ids=["user-456", "user-789"]
    )
    
    assert course.id == "WS25/26-einführung-in-informatik"
    assert course.status == CourseStatus.ACTIVE
    assert len(course.instructor_ids) == 1
    assert len(course.student_ids) == 2

def test_course_archival():
    """Test archiving a course."""
    api = CourseProvisioningAPI(config)
    course = api.create_course(...)
    
    archived = api.archive_course(course.id)
    
    assert archived.status == CourseStatus.ARCHIVED
    assert archived.archived_at is not None
    # Verify enrollments frozen
    assert not api._can_enroll_new_students(course.id)

def test_semester_transition():
    """Test full semester transition."""
    api = CourseProvisioningAPI(config)
    
    # Create courses in WS25/26
    for i in range(5):
        api.create_course(
            title=f"Course {i}",
            semester="WS25/26",
            instructor_ids=["user-123"]
        )
    
    # Transition to SS26
    report = api.semester_transition("WS25/26", "SS26")
    
    assert len(report["archived_courses"]) == 5
    assert report["errors"] == []

def test_role_sync():
    """Test role synchronization engine."""
    engine = RoleSyncEngine(config)
    
    # Set desired enrollments
    desired = {
        "user-1": "instructor",
        "user-2": "student",
        "user-3": "student"
    }
    
    # Mock current state (missing user-3, wrong role for user-2)
    current = {
        "user-1": "instructor",
        "user-2": "tutor"
    }
    
    result = engine.sync_enrollments("course-123", desired, current)
    
    assert result["added"] == 1  # user-3
    assert result["changed"] == 1  # user-2 role
    assert result["removed"] == 0
```

---

## 7. DEPLOYMENT

### 7.1 Configuration

```yaml
# helmfile/environments/default/semester-lifecycle.yaml.gotmpl

semester:
  enabled: true
  current:
    name: "WS25/26"
    type: "wintersemester"
    start_date: "2025-10-01"
    end_date: "2026-03-31"
  
  automation:
    enabled: true
    timezone: "Europe/Berlin"
  
  provisioning:
    auto_archive: true
    archive_retention_years: 5
  
  roles:
    sync_interval_minutes: 15
```

### 7.2 Environment Variables

```bash
# Semester Lifecycle Configuration
SEMESTER_ENABLED=true
SEMESTER_CURRENT=WS25/26
SEMESTER_TYPE=wintersemester
SEMESTER_START_DATE=2025-10-01
SEMESTER_END_DATE=2026-03-31

# Automation
SEMESTER_AUTOMATION_ENABLED=true
SEMESTER_TIMEZONE=Europe/Berlin

# Role Sync
ROLE_SYNC_INTERVAL_MINUTES=15
ROLE_SYNC_ENABLED=true

# Archival
ARCHIVE_AUTO_ARCHIVE=true
ARCHIVE_RETENTION_YEARS=5
```

---

## 8. ACCEPTANCE CRITERIA

### 8.1 Functional Requirements

- [ ] Course provisioning API can create courses on ILIAS and Moodle
- [ ] Course provisioning API can assign roles (instructor, student, tutor)
- [ ] Course archival freezes enrollments and revokes student write access
- [ ] Course archival preserves all data (read-only access maintained)
- [ ] Role synchronization updates enrollments across all platforms
- [ ] Semester transition archives old semester and activates new semester
- [ ] CronJobs execute automation tasks on schedule
- [ ] Audit log records all lifecycle operations

### 8.2 Non-Functional Requirements

- [ ] Course creation completes in <10 seconds
- [ ] Role sync completes for 1000 enrollments in <60 seconds
- [ ] Archival of 100 courses completes in <5 minutes
- [ ] All tests pass (unit + integration)
- [ ] Documentation is bilingual (German/English)
- [ ] No breaking changes to existing functionality

### 8.3 Documentation Requirements

- [ ] User guide for semester lifecycle management
- [ ] API documentation for course provisioning
- [ ] Automation setup guide
- [ ] Troubleshooting guide
- [ ] Integration guide for campus management (v1.5 placeholder)

---

## 9. RISKS & MITIGATIONS

| Risk | Impact | Mitigation |
|:-----|:-------|:----------|
| Semester dates change unexpectedly | Automation runs at wrong time | Manual override capability; configurable dates; admin notification |
| HISinOne integration delayed (v1.5) | Manual course provisioning required | v1.1 uses manual database entries; API ready for v1.5 integration |
| Role mapping conflicts between platforms | Inconsistent access | Standardized role mapping table; platform-specific fallback roles |
| Archive data loss | Permanent data loss | Archive snapshots before archival; 5-year retention; backup verification |
| CronJob failures go unnoticed | Automation gaps | Alerting on job failures; manual trigger capability; audit log monitoring |
| Large enrollment syncs timeout | Partial syncs | Batch processing; progress tracking; resume capability |
| Student data retention (GDPR) | Legal/compliance risk | Configurable retention periods; data minimization; archival policies |

---

## 10. GDPR / DATA SOVEREIGNTY CONSIDERATIONS

### 10.1 Data Retention

- **Active courses**: Full student data (names, emails, IDs)
- **Archived courses**: Read-only access, data preserved for academic record
- **Deleted courses**: Data purged after 5 years (configurable)

### 10.2 Data Minimization

- Only sync roles and essential user attributes
- Do not sync grades or exam data (deferred to v1.5)
- Archive contains only course content, not personal data beyond enrollment

### 10.3 User Rights

- **Right to information**: Students can view their course enrollments
- **Right to erasure**: Account deletion removes from active courses
- **Right to data portability**: Export enrollment history available

---

## 11. TIMELINE

| Task | Estimated Duration | Priority |
|:-----|:-------------------|:---------|
| Design course provisioning API | 2 hours | High |
| Implement role synchronization engine | 3 hours | High |
| Create semester lifecycle manager | 2 hours | High |
| Implement course archival logic | 2 hours | High |
| Create Helm chart for deployment | 2 hours | Medium |
| Write automation cronJobs | 2 hours | Medium |
| Write unit tests | 2 hours | High |
| Write integration tests | 3 hours | High |
| Write bilingual documentation | 2 hours | Medium |
| **Total** | **~20 hours** | |

---

## 12. SUCCESS METRICS

- **Course provisioning time**: <10 seconds per course
- **Role sync accuracy**: 100%
- **Archival success rate**: 99%+
- **Automation uptime**: 99.9%
- **Test coverage**: 90%+

---

## 13. FUTURE ENHANCEMENTS (v1.5+)

- [ ] Direct HISinOne API integration
- [ ] Real-time enrollment webhooks
- [ ] Automated course provisioning from campus management
- [ ] Exam period automation
- [ ] Study progress tracking

---

## 14. APPROVAL

**Plan Reviewed By**: [Pending]
**Plan Approved**: [Pending]
**Implementation Start**: [Date]
**Target Completion**: [Date]

---

## TODOs

- [ ] Create course provisioning API
- [ ] Implement role synchronization engine
- [ ] Create semester lifecycle manager
- [ ] Implement course archival logic
- [ ] Create Helm chart for deployment
- [ ] Write automation cronJobs
- [ ] Write unit tests
- [ ] Write integration tests
- [ ] Write bilingual documentation
- [ ] Pass Final Verification Wave

---

## Final Verification Wave

- [ ] F1: Code Review — All code reviewed, follows patterns, no security issues
- [ ] F2: Test Verification — All tests pass, coverage >90%
- [ ] F3: Documentation Review — All docs complete, bilingual, accurate
- [ ] F4: Integration Verification — Semester lifecycle automation works correctly

---

## References

- [ROADMAP.md](../ROADMAP.md) - Semester Lifecycle Management requirements
- [DFN-AAI Federation Plan](../dfn-aai-saml-federation.md) - Plan structure example
- [ILIAS ECS API](https://github.com/ilias-elearning/ilias-ecs) - Course provisioning reference
- [Moodle Web Services](https://docs.moodle.org/dev/Web_services_API) - Role management
- [Keycloak Admin API](https://www.keycloak.org/docs/latest/server_deployment/) - User/role management

---

*This plan is subject to change based on implementation findings and HISinOne integration requirements.*
