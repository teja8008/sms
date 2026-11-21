import { useEffect, useState } from "react";
import { Link, NavLink, Navigate, Route, Routes, useLocation, useMatch, useParams } from "react-router";
import CompensationInsights from "./CompensationInsights.jsx";
import EmployeeDirectory, { DEFAULT_DIRECTORY_FILTERS } from "./EmployeeDirectory.jsx";
import EmployeeProfile from "./EmployeeProfile.jsx";

export default function App() {
  const [directoryFilters, setDirectoryFilters] = useState(DEFAULT_DIRECTORY_FILTERS);
  const [lastInsightsSearch, setLastInsightsSearch] = useState("");
  const { pathname, search } = useLocation();
  const onInsights = Boolean(useMatch("/insights"));

  useEffect(() => {
    if (onInsights) setLastInsightsSearch(search);
  }, [onInsights, search]);

  useEffect(() => {
    window.scrollTo(0, 0);
  }, [pathname]);

  return (
    <>
      <header className="app-header">
        <div className="app-header-content">
          <div className="app-brand">
            <span className="app-mark" aria-hidden="true">A</span>
            <span>ACME <strong>CompScope</strong></span>
          </div>
          <nav className="app-nav" aria-label="Main navigation">
            <NavLink to="/employees">Employees</NavLink>
            <NavLink to={{ pathname: "/insights", search: onInsights ? search : lastInsightsSearch }}>Insights</NavLink>
          </nav>
        </div>
      </header>
      <Routes>
        <Route path="/" element={<Navigate to="/employees" replace />} />
        <Route path="/employees" element={<EmployeeDirectory filters={directoryFilters} setFilters={setDirectoryFilters} />} />
        <Route path="/employees/:id" element={<EmployeeProfileRoute />} />
        <Route path="/insights" element={<CompensationInsights />} />
        <Route path="*" element={<PageNotFound />} />
      </Routes>
    </>
  );
}

function EmployeeProfileRoute() {
  const { id } = useParams();
  if (!/^[0-9]+$/.test(id)) return <PageNotFound />;

  return <EmployeeProfile key={id} employeeId={id} />;
}

function PageNotFound() {
  return (
    <main className="workspace">
      <div className="page-heading"><h1>Page not found</h1></div>
      <Link className="back-button" to="/employees">Back to directory</Link>
    </main>
  );
}
