# PLAN

## Now: 1.4 (released together with the daily check-in)
- [x] Daily close-reading check-in merged into `develop` (#24, #25)
- [x] TestFlight uploads from `develop` work
- [ ] 1.4 submission materials (`submissions/1.4/`), draft in PR #22, waiting for Yang's review
- [ ] Yang tests the latest `develop` build in TestFlight, then says "推送 App Store"
- [ ] Submit for review (workflow `Submit for review`, `confirm=SUBMIT`), only after Yang's go-ahead
- [ ] After release: merge `develop` into `master`, tag `v1.4`, update `submissions/README.md`

## Open questions for Yang
- TestFlight internal group automatic distribution: confirm the tester receives `develop` builds automatically.
- Docs-only merges into `develop` also trigger a TestFlight upload. Consider adding `paths-ignore` for `*.md`, `docs/**`, `submissions/**`.

## Log
- 2026-10-27: Added AGENTS.md and PLAN.md (pm leader, night run).
