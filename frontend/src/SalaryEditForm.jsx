import { useState } from "react";

export default function SalaryEditForm({ employee, onCancel, onSaved, onReload }) {
  const dates = employee.salary_effective_dates;
  const [values, setValues] = useState({ annual_salary: "", reason: "", effective_date: dates.max });
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState(null);
  const fields = feedback?.fields ?? {};

  function updateField(event) {
    const { name, value } = event.target;
    setValues((current) => ({ ...current, [name]: value }));
  }

  async function saveSalary(event) {
    event.preventDefault();
    setSaving(true);
    setFeedback(null);

    try {
      const response = await fetch(`/api/v1/employees/${employee.id}/salary`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          annual_salary: values.annual_salary.trim(),
          reason: values.reason.trim(),
          effective_date: values.effective_date,
          expected_revision_id: employee.latest_revision_id,
        }),
      });

      if (response.ok) {
        onSaved();
        return;
      }

      const payload = await response.json().catch(() => ({}));
      setFeedback({
        message: payload.error ?? "Unable to save the salary. Please try again.",
        fields: payload.fields,
        reload: response.status === 409 || response.status >= 500,
      });
    } catch {
      setFeedback({ message: "Could not confirm the salary update. Reload the salary before trying again.", reload: true });
    } finally {
      setSaving(false);
    }
  }

  return (
    <section className="panel salary-editor" aria-labelledby="edit-salary-title">
      <h2 id="edit-salary-title">Edit salary</h2>
      <p>Enter the new annual base salary in {employee.currency_code}.</p>
      <form onSubmit={saveSalary}>
        {feedback && <p className="form-error" role="alert">{feedback.message}</p>}
        <fieldset className="salary-fields" disabled={saving || feedback?.reload}>
          <label className="field">
            <span>New annual salary</span>
            <input name="annual_salary" type="text" inputMode="decimal" value={values.annual_salary}
              onChange={updateField} required autoFocus
              aria-invalid={Boolean(fields.annual_salary)}
              aria-describedby={fields.annual_salary ? "annual-salary-error" : undefined} />
            {fields.annual_salary && <span id="annual-salary-error" className="form-error">{fields.annual_salary.join(". ")}</span>}
          </label>
          <label className="field">
            <span>Reason</span>
            <input name="reason" type="text" value={values.reason} onChange={updateField} required
              aria-invalid={Boolean(fields.reason)} aria-describedby={fields.reason ? "salary-reason-error" : undefined} />
            {fields.reason && <span id="salary-reason-error" className="form-error">{fields.reason.join(". ")}</span>}
          </label>
          <label className="field">
            <span>Effective date</span>
            <input name="effective_date" type="date" min={dates.min} max={dates.max} value={values.effective_date}
              onChange={updateField} required aria-invalid={Boolean(fields.effective_date)}
              aria-describedby={fields.effective_date ? "salary-date-error" : undefined} />
            {fields.effective_date && <span id="salary-date-error" className="form-error">{fields.effective_date.join(". ")}</span>}
          </label>
        </fieldset>
        <div className="salary-actions">
          <button type="button" className="secondary-button" onClick={onCancel} disabled={saving}>Cancel</button>
          {feedback?.reload ? (
            <button type="button" className="primary-button" onClick={onReload}>Reload salary</button>
          ) : (
            <button type="submit" className="primary-button" disabled={saving}>{saving ? "Saving…" : "Save salary"}</button>
          )}
        </div>
      </form>
    </section>
  );
}
