import { countryName, formatMoney } from "./format.js";
import SelectFilter from "./SelectFilter.jsx";

const compact = new Intl.NumberFormat("en-US", { notation: "compact", maximumFractionDigits: 2 });

export default function InsightsCharts({ countries, ranges, currency, localSpend, comparisonDepartment, onComparisonChange }) {
  return (
    <div className="insights-charts">
      <SpendChart countries={countries} currency={currency} localSpend={localSpend} />
      <PayRangeChart ranges={ranges} currency={currency} comparisonDepartment={comparisonDepartment}
        onComparisonChange={onComparisonChange} />
    </div>
  );
}

function SpendChart({ countries, currency, localSpend }) {
  const countryCounts = new Map();
  const rows = countries.map((row) => {
    countryCounts.set(row.country_code, (countryCounts.get(row.country_code) ?? 0) + 1);
    return { ...row, spend: localSpend ? row.annual_spend : row.annual_spend_usd };
  });
  rows.sort((left, right) => Number(right.spend) - Number(left.spend));
  const scale = chartScale(Number(rows[0].spend));

  return (
    <section className="panel insights-chart" aria-labelledby="insights-spend-title">
      <div className="insights-chart-heading">
        <h2 id="insights-spend-title">Annual spend by country</h2>
        <p>{localSpend ? `${currency} · Annual base pay` : "USD · Converted at seeded rates"}</p>
      </div>
      <ul className="insights-chart-rows">
        {rows.map((row) => (
          <li key={`${row.country_code}:${row.currency_code}`}>
            <div className="insights-bar-label">
              <span>
                {countryName(row.country_code)}
                {countryCounts.get(row.country_code) > 1 && ` (${row.currency_code})`}
              </span>
              <strong aria-hidden="true" title={formatMoney(row.spend, currency)}>{compact.format(row.spend)}</strong>
              <span className="insights-chart-exact">{formatMoney(row.spend, currency)}</span>
            </div>
            <div className="insights-bar-track" aria-hidden="true">
              <span style={{ width: scale.position(row.spend) }} />
            </div>
          </li>
        ))}
      </ul>
      <ChartAxis ticks={scale.ticks} />
    </section>
  );
}

function PayRangeChart({ ranges, currency, comparisonDepartment, onComparisonChange }) {
  const departmentCounts = new Map();
  for (const row of ranges) {
    departmentCounts.set(row.department, (departmentCounts.get(row.department) ?? 0) + row.headcount);
  }
  const departments = [...departmentCounts.keys()];
  const largestDepartment = departments.reduce((largest, name) =>
    departmentCounts.get(name) > departmentCounts.get(largest) ? name : largest, departments[0]);
  const department = departmentCounts.has(comparisonDepartment) ? comparisonDepartment : largestDepartment;
  const rows = ranges.filter((row) => row.department === department);
  const scale = chartScale(Math.max(...rows.map((row) => Number(row.max_salary))));

  return (
    <section className="panel insights-chart" aria-labelledby="insights-range-title">
      <div className="insights-chart-heading insights-range-heading">
        <div>
          <h2 id="insights-range-title">Pay range by job level</h2>
          <p>{departments.length === 1 ? `${department} · ` : ""}{currency} per year</p>
        </div>
        {departments.length > 1 && (
          <SelectFilter label="Compare levels in" options={departments} value={department} onChange={onComparisonChange} />
        )}
      </div>
      <ul className="insights-chart-rows insights-range-rows">
        {rows.map((row) => {
          const description = `Minimum ${formatMoney(row.min_salary, currency)}, median ${formatMoney(row.median_salary, currency)}, maximum ${formatMoney(row.max_salary, currency)}`;
          return (
            <li key={row.job_level}>
              <span>{row.job_level}</span>
              <div className="insights-range-track" aria-hidden="true" title={description} style={{
                "--range-min": scale.position(row.min_salary),
                "--range-median": scale.position(row.median_salary),
                "--range-max": scale.position(row.max_salary),
              }}>
                <span className="insights-range-line" />
                <span className="insights-range-dot" />
              </div>
              <strong aria-hidden="true">{compact.format(row.median_salary)}</strong>
              <span className="insights-chart-exact">{description}</span>
            </li>
          );
        })}
      </ul>
      <ChartAxis ticks={scale.ticks} className="insights-range-axis" />
      <div className="insights-chart-legend">
        <span><i className="insights-legend-line" aria-hidden="true" /> Min to max</span>
        <span><i className="insights-legend-dot" aria-hidden="true" /> Median</span>
      </div>
    </section>
  );
}

function ChartAxis({ ticks, className = "" }) {
  return (
    <div className={`insights-chart-axis ${className}`} aria-hidden="true">
      {ticks.map((tick, index) => (
        <span key={index} style={{ left: `${index / (ticks.length - 1) * 100}%` }}>{compact.format(tick)}</span>
      ))}
    </div>
  );
}

function chartScale(maximum) {
  const magnitude = 10 ** Math.floor(Math.log10(maximum / 3));
  const step = Math.ceil(maximum / (3 * magnitude)) * magnitude;
  return {
    ticks: [0, step, 2 * step, 3 * step],
    position: (amount) => `${Number(amount) / (3 * step) * 100}%`,
  };
}
