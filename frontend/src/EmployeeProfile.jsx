import { countryName, formatDate, formatMoney } from "./format.js";
import useJson from "./useJson.js";

export default function EmployeeProfile({ employeeId, onBack }) {
  const { data, loading, error, retry } = useJson(
    `/api/v1/employees/${employeeId}`,
    "Unable to load the employee profile. Please try again.",
  );

  return (
    <main className="workspace">
      <button type="button" className="back-button" onClick={onBack} autoFocus>← Back to directory</button>
      {loading && <p role="status">Loading employee profile…</p>}
      {error && (
        <div role="alert">
          <p>{error}</p>
          <button type="button" className="secondary-button" onClick={retry}>Try again</button>
        </div>
      )}
      {!loading && !error && <ProfileContent employee={data.employee} />}
    </main>
  );
}

function ProfileContent({ employee }) {
  return (
    <>
      <div className="page-heading">
        <h1>{employee.full_name}</h1>
        <p>{employee.job_title} · {employee.employee_code}</p>
      </div>
      <section className="panel profile-summary" aria-label="Employee details">
        <div className="salary-summary">
          <span>Annual base salary</span>
          <strong>{formatMoney(employee.annual_salary, employee.currency_code)}</strong>
          <span className={`status status--${employee.status}`}>{employee.status}</span>
        </div>
        <dl className="profile-facts">
          <div><dt>Email</dt><dd>{employee.email}</dd></div>
          <div><dt>Country</dt><dd>{countryName(employee.country_code)}</dd></div>
          <div><dt>Department</dt><dd>{employee.department}</dd></div>
          <div><dt>Job level</dt><dd>{employee.job_level}</dd></div>
          <div><dt>Hired on</dt><dd>{formatDate(employee.hired_on)}</dd></div>
        </dl>
      </section>
      <section className="panel history-section" aria-labelledby="salary-history">
        <h2 id="salary-history">Salary history</h2>
        {employee.salary_revisions.length === 0 ? (
          <p className="state-message">No salary revisions have been recorded.</p>
        ) : (
          <div className="table-scroll" role="region" aria-label="Salary revisions table" tabIndex={0}>
            <table>
              <thead>
                <tr>
                  <th scope="col">Effective date</th>
                  <th scope="col">Reason</th>
                  <th scope="col" className="money">Previous salary</th>
                  <th scope="col" className="money">New salary</th>
                </tr>
              </thead>
              <tbody>
                {employee.salary_revisions.map((revision) => (
                  <tr key={revision.id}>
                    <td>{formatDate(revision.effective_date)}</td>
                    <td>{revision.reason === "initial" ? "Opening salary" : revision.reason}</td>
                    <td className="money">{revision.previous_salary === null ? "—" : formatMoney(revision.previous_salary, revision.currency_code)}</td>
                    <td className="money">{formatMoney(revision.new_salary, revision.currency_code)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </>
  );
}
