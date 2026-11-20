# ACME Employee Salary Management — Product Requirements

## Problem and goal

ACME's HR manager uses spreadsheets to maintain annual salaries for 10,000 employees across six countries. A raise means finding the right row, preserving the old figure, and updating reports that span currencies. The goal is to record the change once and see its effect on compensation spend.

## Core workflows

- **Find an employee.** Search by name, email, or employee code, filter by country, department, and job level, and open a profile from paginated results. Show the employee code and local currency so HR can distinguish people with similar names.
- **Change a salary.** Show the current annual amount and currency. HR enters a positive replacement amount, reason, and effective date. A successful save updates the profile and appends an immutable revision recording the old and new amounts for audit. Reject unchanged amounts and stale edits with a message that lets HR recover.
- **Review pay.** Use country and department filters on the Insights page. Include active employees in headcount and spend. Label every figure with its currency and show an empty state when a filter matches nobody.

## Questions the first release must answer

1. How many active employees does ACME have, and what is their total annual base salary in USD?
2. What are headcount, annual spend, and median salary in each country?
3. What are the minimum, median, and maximum salaries for each department and job level?
4. How has an individual employee's salary changed over time?

## Assumptions and scope

The public demo represents one HR manager, uses synthetic records, and opens without login. Role-based access belongs to a future release. Salary means annual base pay in the employee's ISO currency. Single-country views use local currency. Cross-country views use seeded USD exchange rates so results are reproducible. Every salary change is recorded as an append-only revision for audit and history. Edits take effect on save; the effective date must fall between the latest recorded salary date and today, inclusive.

Employee creation and deactivation follow the core release. Bonuses, equity, tax, and disbursement require separate compensation or payroll rules. Live FX and bulk CSV transfer can wait while we validate the core workflows.

## Release acceptance

On the deployed 10,000-employee dataset, find an active employee paid in USD, raise their salary by $1,000, and verify one new revision, a $1,000 increase in global annual spend, and the same headcount. The salary and revision must survive an application restart.
