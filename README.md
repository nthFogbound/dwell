# Dwell 0.1.0

Dwell is a local-first study app for Windows. Your courses, flashcards and progress are stored on your computer, with no account and no internet connection needed.

## What you can do

- **Organize:** create courses and group them into topics.
- **Make flashcards:** add, edit and delete cards inside each topic.
- **Review:** study due cards with spaced repetition. Cards you remember come back later, and missed cards return sooner.
- **Take quizzes:** multiple-choice quizzes built from your flashcards, for a whole course or a single topic.
- **Track progress:** see how many cards you've mastered, per course and overall, plus your recent quiz scores.

## Keyboard shortcuts

- **Review:** `Space` shows the answer, `←` marks a card missed, `→` marks it remembered.
- **Quiz:** `1`-`4` choose an answer, `Enter` moves to the next question.

## Requirements

- Windows 10 or later (64-bit).
- The **Microsoft Visual C++ Redistributable (x64)**. If the app won't start and reports a missing `VCRUNTIME140.dll` or `MSVCP140.dll`, install it from Microsoft.
- To run it, unzip the whole folder and open `dwell.exe`. Keep all the files together.

## Your data

Everything is stored locally in `%APPDATA%\Dwell\Dwell`. To back it up, copy `dwell.sqlite` from that folder.

## Known limitations

- Course names must be unique, and topic names must be unique within a course (matching ignores upper/lower case).
- If you delete a topic, its flashcards are removed, but past quiz results for that topic stay in your history and appear as whole-course quizzes.
- Windows only, with no sync between devices.

---

**Before you publish, check two lines:**
- The data folder path assumes you set both `CompanyName` and `ProductName` to "Dwell" in `Runner.rc`. Look in `%APPDATA%` and correct the path if it differs.
- If you later confirm dark mode works (following the Windows setting), add "Light and dark themes" under the feature list. I left it out because I haven't seen that confirmed.