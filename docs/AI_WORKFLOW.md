# AI workflow log

## Phase A — Project framing

AI drafted the PRD, design notes, and project rules from the assessment brief. During review, we added individual salary history to the PRD so HR can see how an employee's pay has changed over time.

We checked the currency conversion example by hand. At 0.012 USD per INR, INR 2,000,000 converts to USD 24,000. With a second salary of USD 60,000, the reporting test should expect USD 84,000 in annual spend and a USD 42,000 median.

## Phase B — Application scaffold

AI drafted the minimal Rails setup and a browser spec for the React heading. The spec first failed on the empty page and caught a second failure after the generated Scheduler asset referenced a missing file. We pinned the matching production module locally, then verified the browser spec, RuboCop, and production asset compilation.

After reviewing the frontend workflow, we chose Vite and JSX for the employee screens. AI moved the starter page to React components, configured Vite's Rails API proxy, and wired the GitLab test job to consume the frontend build. We verified a clean npm install, the Vite build, and the browser spec against the built page served by Rails.

## Phase B — Compensation data model

AI drafted the migration and model specs from the design. We added examples that bypass Rails validations to check PostgreSQL's unique keys, foreign keys, and salary constraints. We also checked that an employee can have one opening revision and later revisions while existing revisions stay read-only through Rails record methods. We verified the migration could roll back and reapply and ran the full test suite.
