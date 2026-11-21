import { useId, useState } from "react";
import { countryName, formatMoney } from "./format.js";
import useJson from "./useJson.js";

const DEFAULT_FILTERS = { q: "", country: "", department: "", job_level: "", sort: "name", direction: "asc", page: 1 };
const EMPTY_OPTIONS = { countries: [], departments: [], job_levels: [] };
const SORT_OPTIONS = [
  ["name:asc", "Name A–Z"],
  ["name:desc", "Name Z–A"],
  ["employee_code:asc", "Employee code"],
  ["department:asc", "Department"],
  ["job_level:asc", "Level low to high"],
  ["job_level:desc", "Level high to low"],
];
const countFormat = new Intl.NumberFormat("en-US");

function SelectFilter({ label, all, options, value, onChange, format = (option) => option }) {
  const id = useId();

  return (
    <div className="field">
      <label htmlFor={id}>{label}</label>
      <select id={id} value={value} onChange={(event) => onChange(event.target.value)}>
        {all && <option value="">{all}</option>}
        {options.map((option) => <option key={option} value={option}>{format(option)}</option>)}
      </select>
    </div>
  );
}

export default function EmployeeDirectory({ onSelect, refreshVersion }) {
  const [search, setSearch] = useState("");
  const [filters, setFilters] = useState(DEFAULT_FILTERS);
  const params = new URLSearchParams(Object.entries(filters).filter(([, value]) => value !== ""));
  const { data, loading, error, retry } = useJson(
    `/api/v1/employees?${params}`, "Unable to load employees. Please try again.", refreshVersion,
  );
  const options = data?.filter_options ?? EMPTY_OPTIONS;
  const hasFilters = [filters.q, filters.country, filters.department, filters.job_level].some(Boolean);

  function applyFilters(changes) {
    setFilters((current) => ({ ...current, ...changes, page: 1 }));
  }

  function runSearch(event) {
    event.preventDefault();
    applyFilters({ q: search.trim() });
  }

  function selectSort(event) {
    const [sort, direction] = event.target.value.split(":");
    applyFilters({ sort, direction });
  }

  function clearFilters() {
    setSearch("");
    setFilters(DEFAULT_FILTERS);
  }

  function changePage(page) {
    setFilters((current) => ({ ...current, page }));
  }

  return (
    <main className="workspace">
      <div className="page-heading">
        <h1>Employee directory</h1>
        <p>Search employees and review annual base pay in local currency.</p>
      </div>

      <section className="panel" aria-label="Employee results">
        <div className="toolbar">
          <form className="search-form" onSubmit={runSearch}>
            <label className="field search-field">
              <span>Search employees</span>
              <input type="search" value={search} placeholder="Name, email, or employee code"
                onChange={(event) => setSearch(event.target.value)} />
            </label>
            <button type="submit" className="primary-button">Search</button>
          </form>

          <div className="filters">
            <SelectFilter label="Country" all="All countries" options={options.countries}
              value={filters.country} onChange={(country) => applyFilters({ country })} format={countryName} />
            <SelectFilter label="Department" all="All departments" options={options.departments}
              value={filters.department} onChange={(department) => applyFilters({ department })} />
            <SelectFilter label="Job level" all="All levels" options={options.job_levels}
              value={filters.job_level} onChange={(job_level) => applyFilters({ job_level })} />
            <div className="field sort-field">
              <label htmlFor="employee-sort">Sort by</label>
              <select id="employee-sort" value={`${filters.sort}:${filters.direction}`} onChange={selectSort}>
                {SORT_OPTIONS.map(([value, label]) => <option key={value} value={value}>{label}</option>)}
              </select>
            </div>
            {hasFilters && <button type="button" className="secondary-button" onClick={clearFilters}>Clear filters</button>}
          </div>
        </div>

        {loading && <p className="state-message" role="status">Loading employees…</p>}
        {error && (
          <div className="state-message" role="alert">
            <p>{error}</p>
            <button type="button" className="secondary-button" onClick={retry}>Try again</button>
          </div>
        )}
        {!loading && !error && (
          <DirectoryResults data={data} hasFilters={hasFilters} onSelect={onSelect} onPageChange={changePage} />
        )}
      </section>
    </main>
  );
}

function DirectoryResults({ data, hasFilters, onSelect, onPageChange }) {
  const { employees, pagination } = data;
  const { page, per_page: perPage, total_count: totalCount, total_pages: totalPages } = pagination;

  if (employees.length === 0) {
    return <p className="state-message" role="status">{hasFilters ? "No employees match your search and filters." : "No employees have been added yet."}</p>;
  }

  const first = (page - 1) * perPage + 1;
  const last = first + employees.length - 1;
  const range = first === last ? countFormat.format(first) : `${countFormat.format(first)}–${countFormat.format(last)}`;
  const employeeLabel = totalCount === 1 ? "employee" : "employees";

  return (
    <>
      <p className="result-count" role="status">
        Showing {range} of {countFormat.format(totalCount)} {employeeLabel}
      </p>
      <div className="table-scroll" role="region" aria-label="Employee table" tabIndex={0}>
        <table>
          <thead>
            <tr>
              <th scope="col">Employee</th>
              <th scope="col">Department</th>
              <th scope="col">Country</th>
              <th scope="col">Level</th>
              <th scope="col" className="money">Annual salary</th>
              <th scope="col">Status</th>
            </tr>
          </thead>
          <tbody>
            {employees.map((employee) => (
              <tr key={employee.id}>
                <td>
                  <button type="button" className="employee-link" onClick={(event) => onSelect(employee.id, event.currentTarget)}
                    aria-label={`View ${employee.full_name}, ${employee.employee_code}`}>
                    {employee.full_name}
                  </button>
                  <span className="cell-secondary">{employee.employee_code}</span>
                </td>
                <td>{employee.department}<span className="cell-secondary">{employee.job_title}</span></td>
                <td>{countryName(employee.country_code)}</td>
                <td>{employee.job_level}</td>
                <td className="money">{formatMoney(employee.annual_salary, employee.currency_code)}</td>
                <td><span className={`status status--${employee.status}`}>{employee.status}</span></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <nav className="pagination" aria-label="Employee pages">
        <button type="button" className="secondary-button" disabled={page <= 1} onClick={() => onPageChange(page - 1)}>Previous</button>
        <span>Page {countFormat.format(page)} of {countFormat.format(totalPages)}</span>
        <button type="button" className="secondary-button" disabled={page >= totalPages} onClick={() => onPageChange(page + 1)}>Next</button>
      </nav>
    </>
  );
}
