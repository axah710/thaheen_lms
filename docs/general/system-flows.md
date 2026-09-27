# System Flows & Architecture Diagrams

> **Visual architectural diagrams, state machine progressions, and lifecycle interaction flows.**

---

## 1. Domain Entities & Relationships

```mermaid
classDiagram
    class Course {
        +String id
        +String title
        +String instructor
        +String thumbnail
        +List~Section~ sections
        +List~Lesson~ allLessonsOrdered
        +int totalDurationSec
        +int totalLessonsCount
    }

    class Section {
        +String id
        +String courseId
        +String title
        +int orderIndex
        +List~Lesson~ lessons
        +int totalDurationSec
    }

    class Lesson {
        +String id
        +String courseId
        +String sectionId
        +String title
        +int durationSec
        +String videoAssetPath
        +int globalOrderIndex
    }

    class CourseProgress {
        +String courseId
        +Map~String, LessonProgress~ lessonProgressMap
        +int completedCount
        +int progressPercentage
    }

    class LessonProgress {
        +String lessonId
        +String courseId
        +int lastPositionSec
        +bool isCompleted
        +DateTime lastAccessedAt
    }

    Course "1" *-- "many" Section : contains
    Section "1" *-- "many" Lesson : contains
    CourseProgress "1" *-- "many" LessonProgress : tracks
```

---

## 2. 90% Auto-Completion State Progression

```mermaid
stateDiagram-v2
    [*] --> NotStarted : Lesson Opened at 00:00
    NotStarted --> InProgress : Playback Position > 0
    InProgress --> InProgress : Position < 0.90 * Duration (5s Debounced)
    InProgress --> Completed : Position >= ceil(0.90 * Duration) (Immediate Flush!)
    Completed --> Completed : User scrubs backward (< 90%) [Idempotent]
    Completed --> Completed : Lesson Replayed from 00:00 [Irreversible]
```

---

## 3. Sequential Unlocking Flow Across Sections

```mermaid
flowchart TD
    Start([Evaluate Lesson Status]) --> CheckFirst{Is Lesson 1 in Section 1?}
    CheckFirst -- Yes --> Unlocked[Status: notStarted / inProgress / completed]
    CheckFirst -- No --> FindPrev[Locate Lesson N-1 via globalOrderIndex]
    FindPrev --> CheckPrevCompleted{Is Lesson N-1 Completed?}
    CheckPrevCompleted -- Yes --> UnlockCurrent[Status: notStarted / inProgress / completed]
    CheckPrevCompleted -- No --> LockCurrent[Status: locked]
    
    LockCurrent --> TapAction{User Taps Lesson Tile}
    TapAction --> Intercept[Intercept Navigation]
    Intercept --> ShowToast[Display Debounced Arabic SnackBar:\n'يجب إكمال الدرس السابق أولاً لفتح هذا الدرس']
    
    UnlockCurrent --> TapActionUnlocked{User Taps Lesson Tile}
    TapActionUnlocked --> OpenPlayer[Navigate to LessonPlayerPage]
```

---

## 4. Hybrid Persistence & Lifecycle Flush Flow

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant Player as LessonPlayerPage
    participant Cubit as LessonPlayerCubit
    participant Repo as ProgressRepositoryImpl
    participant Storage as SharedPreferences

    User->>Player: Play Video
    loop Every 500ms Playback Tick
        Player->>Cubit: onPositionChanged(pos)
        Cubit->>Repo: recordPlaybackPosition(pos)
        Note over Repo: Accumulate in memory buffer
    end

    opt After 5 Seconds Continuous Playback
        Repo->>Storage: commit dirty buffer to disk
    end

    alt Immediate Flush: Pause / Seek / 90% Threshold
        User->>Player: Tap Pause or Seek
        Player->>Cubit: togglePlayPause()
        Cubit->>Repo: flush()
        Repo->>Storage: commit dirty buffer immediately
    else Immediate Flush: App Backgrounded
        Note over Player: AppLifecycleListener detects state change
        Player->>Player: onPause / onInactive / onHide / onDetach
        Player->>Repo: flush()
        Repo->>Storage: commit dirty buffer immediately
    end
```

---

## 5. Zero Red Screens Fault Tolerance Flow

```mermaid
flowchart TD
    Init[Load Course / Play Video] --> Check{Operation Succeeds?}
    Check -- Yes --> RenderUI[Render Pristine Arabic UI]
    Check -- Video Corrupt / Missing --> CatchInCubit[Catch PlatformException in Cubit]
    CatchInCubit --> InPlayerCard[Render InPlayerErrorCard:\nArabic Message + Retry + Return Actions]
    
    Check -- Course Has 0 Lessons --> SafeCalc[CourseProgressCalculator: 0% Progress]
    SafeCalc --> EmptyView[Render EmptyCourseView:\n'لا توجد دروس متاحة حالياً في هذه الدورة']
    
    Check -- Unhandled Widget Crash --> Boundary[Top-Level CustomErrorWidget Interceptor]
    Boundary --> CrashCard[Render Arabic Fallback Card with Dignified Error Copy]
```
