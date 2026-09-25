# Thaheen – Flutter Screening Task

## Mini Offline LMS with Video Player

Thanks for taking the time to do this task. It is intentionally small. We care much more about **how** you build it than how much you build.

- **Time box:** 4–6 hours of work. Please don't spend more; tell us what you'd do with more time instead.  
- **Deadline:** 3 days from receiving this task.  
- **No backend and no API calls.** Everything runs offline from bundled assets.

---

## The product

Thaheen is an Arabic-first learning platform for health-sciences students. Students buy courses and watch recorded video lessons. Build a tiny version of the student app.

---

## Data (bundled, offline)

1. Create `assets/data/courses.json` with **2 courses**, each with **2 sections**, each section with **2–3 lessons**.  
2. Put **2–3 short MP4 files** (any royalty-free clips, under 10 MB each) in `assets/videos/` and reference them from the JSON.  
3. Suggested shape (you may change it and explain why):

{

  "courses": \[

    {

      "id": "anatomy-101",

      "title": "مقدمة في التشريح",

      "instructor": "د. سارة",

      "thumbnail": "assets/images/anatomy.png",

      "sections": \[

        {

          "id": "s1",

          "title": "الجهاز الهيكلي",

          "lessons": \[

            { "id": "l1", "title": "العظام", "durationSec": 95, "video": "assets/videos/lesson1.mp4" }

          \]

        }

      \]

    }

  \]

}

---

## Required features

### 1\. Courses screen

- List of courses: thumbnail, title, instructor, lesson count, and **progress %**.  
- A **"Continue watching"** card at the top if the student has an unfinished lesson.

### 2\. Course details screen

- Sections and lessons, each lesson with its duration.  
- A status on each lesson: not started / in progress / completed.  
- **Sequential unlock:** a lesson is locked until the previous one is completed. Tapping a locked lesson shows a friendly message.

### 3\. Lesson player screen

- Play/pause, seek bar, current time and duration.  
- Playback speed: **1x / 1.25x / 1.5x / 2x**.  
- **Fullscreen/landscape** support.  
- **Resume** from the last watched position when the lesson is reopened.  
- A lesson is **completed automatically at 90% watched**.  
- A **"Next lesson"** button that respects the unlock rule.

### 4\. Local persistence

- Progress (positions and completed lessons) must **survive an app restart**.  
- Use any local storage you like (Hive, Isar, SharedPreferences, sqflite) and justify your choice in the README.

### 5\. Arabic-first and RTL

- The UI is in **Arabic with correct RTL layout** (icons, paddings and the seek bar direction make sense).  
- Bonus: an Arabic/English switch.

### 6\. States and errors

- Handle loading, empty (e.g. a course with no lessons) and error states (e.g. a missing or corrupt video file) cleanly. No red screens.

### 7\. Tests

- At least **3 unit tests** for your progress logic (the 90% completion rule, the unlock rule, the progress % calculation).

---

## Technical expectations

- Flutter stable, null-safe.  
- A state management approach of your choice (Bloc/Cubit, Riverpod or Provider), used consistently.  
- A clear separation between data, domain/logic and UI. Don't over-engineer it.  
- `video_player` (optionally with `chewie`) or any package you prefer.  
- Navigation with `go_router` or Navigator 2.0.

---

## Bonus (optional, only if you have time)

- Dark mode.  
- Search courses.  
- Per-lesson notes saved locally.  
- Remember the last playback speed.  
- Widget tests.

---

## What to send

1. A **GitHub repository link** (public, or give us access).  
2. A **README** covering:  
   - How to run the app.  
   - Your architecture and state-management choices, and why.  
   - Trade-offs, known issues, and what you'd do with more time.  
   - Roughly how long you spent.  
3. A **2–3 minute screen recording** of the app, or an APK.

---

## What we look for

- Clean, readable, maintainable code over lots of features.  
- Correct handling of state, restarts and edge cases.  
- Good RTL/Arabic UX.  
- Clear reasoning in your README.  
- Honest scope: it's fine to skip things if you explain why.

Good luck, and feel free to message us if anything is unclear. Asking good questions counts in your favour.

---

## Key point

- Everything must run offline from bundled files. No API calls
