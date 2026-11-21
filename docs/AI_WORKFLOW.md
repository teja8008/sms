# AI workflow log

## Phase A — Project framing

AI drafted the PRD, design notes, and project rules from the assessment brief. During review, we added individual salary history to the PRD so HR can see how an employee's pay has changed over time.

We checked the currency conversion example by hand. At 0.012 USD per INR, INR 2,000,000 converts to USD 24,000. With a second salary of USD 60,000, the reporting test should expect USD 84,000 in annual spend and a USD 42,000 median.

## Phase B — Application scaffold

AI drafted the minimal Rails setup and a browser spec for the React heading. The spec first failed on the empty page and caught a second failure after the generated Scheduler asset referenced a missing file. We pinned the matching production module locally, then verified the browser spec, RuboCop, and production asset compilation.

After reviewing the frontend workflow, we chose Vite and JSX for the employee screens. AI moved the starter page to React components, configured Vite's Rails API proxy, and wired the GitLab test job to consume the frontend build. We verified a clean npm install, the Vite build, and the browser spec against the built page served by Rails.

## Phase B — Compensation data model

AI drafted the migration and model specs from the design. We added examples that bypass Rails validations to check PostgreSQL's unique keys, foreign keys, and salary constraints. We also checked that an employee can have one opening revision and later revisions while existing revisions stay read-only through Rails record methods. We verified the migration could roll back and reapply and ran the full test suite.

## Phase B — Demo data

AI drafted the batched seed and its tests. We used PostgreSQL's returned rows to create opening revisions only for employees inserted in the same transaction. We verified that a failed revision write rolls back its employee batch and that rerunning the full 10,000-employee seed preserves an edited salary and its revision history.

## Phase B — Employee directory

AI drafted the query and API specs before implementing the directory. We verified that search treats wildcard characters literally and that equal names retain a stable order across pages. The browser test checked search, filtering, salary history, and the return to the same results. With 10,000 employees, the 25-row and 100-row pages both used five employee queries.

## Phase B — Salary updates

AI drafted the request specs and transaction service. We used the employee row lock to keep writes and revision-token checks together. A test on separate PostgreSQL connections verified that only one of two concurrent edits could save. We also forced the audit insert to fail and checked that current pay rolled back. Chrome verified form errors, stale-edit recovery, and updated pay in both the profile and directory.

## Phase B — Compensation insights

AI drafted the analytics query and tests around the hand-calculated US and India example. We checked that the median retains a half cent and that the report counts current pay once even when an employee has several revisions. Chrome verified that country filtering switches to INR and that a saved USD 1,000 raise changes the report total from USD 84,000 to USD 85,000.

HR dashboard design review led to two charts using the existing app palette. The React implementation reads country spend and job-level pay ranges from the analytics API. We rebuilt the Rails-served frontend and confirmed its bundle includes both charts.

## Phase B — Page URLs

After feedback that a refresh returned to the directory, we added React Router for the directory, employee profiles, and Insights. Rails serves the app at each path. Insights uses query parameters to restore the report filters on refresh. The frontend build passed. The updated browser specs cover deep links, refresh, and browser history for review.

## Phase C — Deployment rehearsal

We drafted a Render Blueprint for one Rails service and a separate Neon demo database. The Blueprint passed Render's published schema. A local production rehearsal loaded 10,000 synthetic employees, served direct page URLs and compiled assets, and confirmed that a $1,000 raise and its audit entry persisted after restarting Rails. The rehearsal also exposed a schema dump during production migrations, so we disabled production schema dumps.

We compared fresh development and production databases and verified that the seeded employee data matched. A seed rerun after the raise preserved the salary, its revision, and the total employee count. The release process seeds the demo database during initial setup and applies migrations before each deploy.
