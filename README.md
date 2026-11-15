# june-build

Manual build pipeline for the June Android app (`io.element.android.june`).

- The app source is kept in a separate private repository. This repository holds only the build workflow.
- Builds run only when the maintainer starts them by hand (`workflow_dispatch`). Nothing runs on push, pull requests or a schedule.
- Build outputs and the full build log are encrypted for the maintainer before upload. They are kept for one day, and finished runs are deleted.
- Issues, pull requests and discussions are disabled. This repository does not accept contributions.
