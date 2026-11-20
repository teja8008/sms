# Project rules for AI agents

- Read `docs/PRD.md` for product scope and `docs/DESIGN.md` for the data model and API boundaries before changing behavior.
- Work in small, reviewable commits. For each business rule, write a failing example, implement it, refactor, and commit the passing tests with the change.
- Use Rails, PostgreSQL, and React written in plain JavaScript. Serve React through Rails import maps and keep components in `app/javascript/`. Keep controllers focused on HTTP, multi-step writes in `app/services/`, and reporting queries in `app/queries/`.
- Store annual salaries as `NUMERIC(14,2)`. Use decimal arithmetic in Ruby and send money as decimal strings in JSON. Preserve the ISO currency code with every amount.
- Report single-country pay in local currency and convert each salary using its seeded USD rate before combining countries. Round at the display boundary.
- Update the employee and append the salary revision in one database transaction. Keep the revision history when an employee becomes inactive.
- Run search, filtering, pagination, and analytics in PostgreSQL. Measure against the 10,000-employee seed before adding indexes or caching.
- Use synthetic employee data in the public demo. Keep credentials in environment variables.
- Keep RSpec examples small and deterministic. Use JavaScript-enabled system specs for behavior that depends on the browser. Run the relevant specs and linters before each implementation commit.
- Record significant AI assistance in `docs/AI_WORKFLOW.md` as it happens. Include the prompt or task, what was accepted or changed, and how the result was verified.
