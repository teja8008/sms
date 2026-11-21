# ACME CompScope

Employee salary management for ACME HR. Search the directory, then open a profile to review or edit annual base pay and see the salary history. Open **Insights** for active headcount, annual spend, and pay by country, department, and level.

## Run locally

Install Ruby 4.0.9 with Bundler and Node.js 22.12 or newer. Start PostgreSQL and use a local role that can create the development and test databases. Rails connects to `127.0.0.1:5432` by default. Set `PGUSER` and supply its password through `PGPASSWORD` or a PostgreSQL password file. Set `PGHOST` or `PGPORT` if PostgreSQL uses a different address.

For example, in PowerShell, replace `your_local_role` with your PostgreSQL username.

```powershell
$env:PGUSER = "your_local_role"
$credential = Get-Credential -UserName $env:PGUSER -Message "Local PostgreSQL login"
$env:PGPASSWORD = $credential.GetNetworkCredential().Password
```

Start Rails from the repository root in the terminal with your PostgreSQL credentials.

```sh
bundle config set --local path vendor/bundle
bundle install
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails server
```

In a second terminal, start Vite.

```sh
cd frontend
npm ci
npm run dev
```

Open <http://localhost:5173>. Vite reloads React changes and proxies `/api` requests to Rails on port 3000. On Windows PowerShell, use `npm.cmd` for these commands if script execution is disabled.

## Load demo data

Run this from the repository root after migrating the database.

```sh
bundle exec rails db:seed
```

On an empty database, the seed creates 10,000 synthetic employees across six countries and one opening salary revision for each employee. Rerunning it inserts missing demo employees with their opening revisions and preserves existing salaries, rates, and history.

## Run checks

Install Chrome for the browser smoke test. Selenium can download the matching ChromeDriver on the first run. On Linux, you can use Chromium and its matching driver on `PATH` and set `CHROME_BIN` to the Chromium executable.

```sh
npm --prefix frontend ci
npm --prefix frontend run build
bundle exec rubocop
bundle exec rspec
```

Run these commands from the repository root. The build writes to `public/frontend/`. The browser specs cover the directory, salary edits, and the effect of a raise on Insights. GitLab CI builds the same artifact, then runs RuboCop, PostgreSQL migrations, and RSpec with headless Chromium.

To preview the deployment layout locally, build the frontend and open <http://localhost:3000> with Rails running.

## Deploy the demo

1. Confirm CI passes on `main`. Create a Neon PostgreSQL project in Singapore for the synthetic demo data.
2. In Render, create a Blueprint from the GitLab repository. [render.yaml](render.yaml) defines one paid Ruby web service in Singapore. Enter the Neon connection string with TLS as `DATABASE_URL` when prompted. Render generates `SECRET_KEY_BASE`.
3. Render installs the locked dependencies, builds the React frontend, and runs `bundle exec rails db:migrate` before starting the service. Once the service is healthy, run `bundle exec rails db:seed` once in the Render shell to load the same 10,000 synthetic employees as local development.
4. Open the assigned HTTPS URL. Verify `/up`, the directory, an employee profile, and a filtered Insights link. Add $1,000 to an active USD employee's annual salary and check the new revision, the $1,000 increase in global spend, and the baseline headcount. Restart the service and check the saved results again.

## Project documents

- [Product requirements](docs/PRD.md)
- [System design](docs/DESIGN.md)
- [AI workflow log](docs/AI_WORKFLOW.md)
