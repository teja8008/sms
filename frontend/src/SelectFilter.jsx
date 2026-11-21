import { useId } from "react";

export default function SelectFilter({ label, all, options, value, onChange, format = (option) => option }) {
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
