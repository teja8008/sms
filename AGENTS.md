# ACME engineering workflow

## Planning and verification

- Start with the requested milestone. Use `docs/PRD.md` for product scope and `docs/DESIGN.md` for the data model and API boundaries. Consult the local implementation spec when present.
- When model choice is available, use a stronger reasoning model for ambiguous plans and high-risk design or review. Use the lowest-cost capable model for clear, testable work such as scaffolding or routine edits. Escalate when a failure exposes a gap in the plan or the work involves tricky money, concurrency, or security behavior.
- Work in small slices. Read the affected code, callers, and specs. Write a failing example for new behavior, implement it, refactor, and commit the passing tests with the change. Reuse existing code and framework features before adding abstractions or dependencies. Use `$ponytail` when available for focused work.
- Keep RSpec fixtures small and deterministic. Use JavaScript-enabled system specs for browser behavior. Run the focused example while developing, then review the diff and run the relevant suites and RuboCop before committing. Limit tool output to what helps assess the change or diagnose a failure.
- Summarize the changes, checks run, and open decisions. In `docs/AI_WORKFLOW.md`, record significant prompts or tasks, what changed after review, and how you verified the result. Put verified setup and release commands in the README.

## Application conventions

- Use Rails, PostgreSQL, and Vite with React in JavaScript. Keep JSX components in `frontend/src/`, HTTP handling in Rails controllers, multi-step writes in `app/services/`, and reporting queries in `app/queries/`.
- Store annual salaries as `NUMERIC(14,2)` and use decimal arithmetic. Send money as decimal strings with ISO currency codes. Use local currency for one country and seeded USD rates for cross-country totals. Round for display.
- Update current pay and append its revision in one transaction. Handle conflicting edits explicitly and preserve revision history when an employee becomes inactive.
- Run search, filtering, pagination, and analytics in PostgreSQL. Measure queries against the 10,000-employee seed before adding indexes or caching. Keep this benchmark separate from the fast spec suite.
- Use synthetic employee data for the public demo and keep credentials in environment variables.
