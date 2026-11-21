# ACME CompScope

Employee salary management for ACME HR. Search the directory, then open a profile to review or edit annual base pay and see the salary history.

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

Run these commands from the repository root. The build writes to `public/frontend/`. The browser specs exercise directory search, salary history, salary edits, and stale-edit recovery through Rails. GitLab CI builds the same artifact, then runs RuboCop, PostgreSQL migrations, and RSpec with headless Chromium.

To preview the deployment layout locally, build the frontend and open <http://localhost:3000> with Rails running.

## Project documents

- [Product requirements](docs/PRD.md)
- [System design](docs/DESIGN.md)
- [AI workflow log](docs/AI_WORKFLOW.md)
