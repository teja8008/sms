import { useState } from "react";
import { useSearchParams } from "react-router";
import { countryName, formatMoney } from "./format.js";
import InsightsCharts from "./InsightsCharts.jsx";
import SelectFilter from "./SelectFilter.jsx";
import useJson from "./useJson.js";

const countFormat = new Intl.NumberFormat("en-US");
const EMPTY_OPTIONS = { countries: [], departments: [] };

export default function CompensationInsights() {
  const [searchParams, setSearchParams] = useSearchParams();
  const [comparisonDepartment, setComparisonDepartment] = useState("");
  const country = (searchParams.get("country") ?? "").trim().toUpperCase();
  const department = (searchParams.get("department") ?? "").trim();
  const filters = new URLSearchParams();
  if (country) filters.set("country", country);
  if (department) filters.set("department", department);
  const { data, loading, error, retry } = useJson(
    `/api/v1/analytics?${filters}`, "Unable to load compensation insights. Please try again.",
  );
  const options = data?.filter_options ?? EMPTY_OPTIONS;

  function changeFilter(name, value) {
    const nextFilters = new URLSearchParams(filters);
    if (value) {
      nextFilters.set(name, value);
    } else {
      nextFilters.delete(name);
    }
    setSearchParams(nextFilters, { replace: true });
  }

  return (
    <main className="workspace">
      <div className="insights-header">
        <div className="page-heading">
          <h1>Compensation insights</h1>
          <p>Annual base pay for active employees.</p>
        </div>
        <section className="filters" aria-label="Report filters">
          <SelectFilter label="Country" all="All countries" options={options.countries}
            value={country} format={countryName} onChange={(value) => changeFilter("country", value)} />
          <SelectFilter label="Department" all="All departments" options={options.departments}
            value={department} onChange={(value) => changeFilter("department", value)} />
          {(country || department) && (
            <button type="button" className="secondary-button"
              onClick={() => setSearchParams({}, { replace: true })}>Clear filters</button>
          )}
        </section>
      </div>

      {loading && <p className="state-message" role="status">Loading compensation insights…</p>}
      {error && (
        <div className="state-message" role="alert">
          <p>{error}</p>
          <button type="button" className="secondary-button" onClick={retry}>Try again</button>
        </div>
      )}
      {!loading && !error && (
        <InsightReport data={data} country={country} comparisonDepartment={comparisonDepartment}
          onComparisonChange={setComparisonDepartment} />
      )}
    </main>
  );
}

function InsightReport({ data, country, comparisonDepartment, onComparisonChange }) {
  const { summary, country_breakdown: countries, department_level_ranges: ranges } = data;

  return (
    <>
      <dl className="insights-metrics" aria-label="Compensation summary">
        <div className="panel">
          <dt>Active employees</dt>
          <dd>{countFormat.format(summary.headcount)}</dd>
        </div>
        <div className="panel insights-spend-metric">
          <dt>Annual spend</dt>
          <dd>{formatMoney(summary.annual_spend, summary.currency_code)}</dd>
        </div>
        <div className="panel">
          <dt>Median annual salary</dt>
          <dd>{summary.median_salary === null ? "—" : formatMoney(summary.median_salary, summary.currency_code)}</dd>
        </div>
      </dl>

      {summary.headcount === 0 ? (
        <p className="panel state-message" role="status">No active employees match these filters.</p>
      ) : (
        <>
          <InsightsCharts countries={countries} ranges={ranges} currency={summary.currency_code}
            localSpend={Boolean(country) && countries.length === 1}
            comparisonDepartment={comparisonDepartment} onComparisonChange={onComparisonChange} />
          <details className="panel insights-details">
            <summary>View detailed breakdown</summary>
            <section className="insights-table" aria-label="Country breakdown">
              <h2>Country breakdown</h2>
              <div className="table-scroll" role="region" aria-label="Country pay table" tabIndex={0}>
                <table>
                  <thead>
                    <tr>
                      <th scope="col">Country</th>
                      <th scope="col" className="money">Employees</th>
                      <th scope="col" className="money">Local spend</th>
                      <th scope="col" className="money">Local median</th>
                      <th scope="col" className="money">USD spend</th>
                      <th scope="col" className="money">USD median</th>
                    </tr>
                  </thead>
                  <tbody>
                    {countries.map((row) => (
                      <tr key={`${row.country_code}:${row.currency_code}`}>
                        <td>{countryName(row.country_code)}</td>
                        <td className="money">{countFormat.format(row.headcount)}</td>
                        <td className="money">{formatMoney(row.annual_spend, row.currency_code)}</td>
                        <td className="money">{formatMoney(row.median_salary, row.currency_code)}</td>
                        <td className="money">{formatMoney(row.annual_spend_usd, "USD")}</td>
                        <td className="money">{formatMoney(row.median_salary_usd, "USD")}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </section>
            <section className="insights-table" aria-labelledby="pay-range-title">
              <h2 id="pay-range-title">Pay by department and level</h2>
              <div className="table-scroll" role="region" aria-label="Department pay table" tabIndex={0}>
                <table>
                  <thead>
                    <tr>
                      <th scope="col">Department</th>
                      <th scope="col">Level</th>
                      <th scope="col" className="money">Employees</th>
                      <th scope="col" className="money">Minimum</th>
                      <th scope="col" className="money">Median</th>
                      <th scope="col" className="money">Maximum</th>
                    </tr>
                  </thead>
                  <tbody>
                    {ranges.map((row) => (
                      <tr key={`${row.department}:${row.job_level}`}>
                        <td>{row.department}</td>
                        <td>{row.job_level}</td>
                        <td className="money">{countFormat.format(row.headcount)}</td>
                        <td className="money">{formatMoney(row.min_salary, row.currency_code)}</td>
                        <td className="money">{formatMoney(row.median_salary, row.currency_code)}</td>
                        <td className="money">{formatMoney(row.max_salary, row.currency_code)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </section>
          </details>
        </>
      )}
    </>
  );
}
