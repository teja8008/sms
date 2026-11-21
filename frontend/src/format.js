const countries = new Intl.DisplayNames(["en"], { type: "region" });
const dates = new Intl.DateTimeFormat("en-GB", { dateStyle: "medium", timeZone: "UTC" });

export function countryName(code) {
  return countries.of(code) || code;
}

export function formatMoney(amount, currency) {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency,
    currencyDisplay: "code",
  }).format(amount);
}

export function formatDate(date) {
  return dates.format(new Date(date));
}
