import { useRef, useState } from "react";
import EmployeeDirectory from "./EmployeeDirectory.jsx";
import EmployeeProfile from "./EmployeeProfile.jsx";

export default function App() {
  const [employeeId, setEmployeeId] = useState(null);
  const profileTrigger = useRef(null);

  function openProfile(id, button) {
    profileTrigger.current = button;
    setEmployeeId(id);
    window.scrollTo(0, 0);
  }

  function closeProfile() {
    setEmployeeId(null);
    requestAnimationFrame(() => profileTrigger.current?.focus());
  }

  return (
    <>
      <header className="app-header">
        <div className="app-brand">
          <span className="app-mark" aria-hidden="true">A</span>
          <span>ACME <strong>CompScope</strong></span>
        </div>
      </header>
      <div hidden={employeeId !== null}>
        <EmployeeDirectory onSelect={openProfile} />
      </div>
      {employeeId !== null && <EmployeeProfile employeeId={employeeId} onBack={closeProfile} />}
    </>
  );
}
