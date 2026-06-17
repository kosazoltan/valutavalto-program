# Anti-Test-Hacking Rubric

Fail patch if:
- tests changed after freeze
- assertions weakened
- skip/only/todo added
- snapshots updated without approval
- fixtures manipulated
- hardcoded expected values added
- environment bypass added
- test-only branch added
- CI/test discovery weakened
