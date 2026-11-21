import { useEffect, useState } from "react";

export default function useJson(url, fallbackError) {
  const [result, setResult] = useState(null);
  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    const controller = new AbortController();

    async function load() {
      try {
        const response = await fetch(url, { signal: controller.signal });
        const payload = await response.json();
        if (controller.signal.aborted) return;

        if (response.ok) {
          setResult({ url, attempt, data: payload });
        } else {
          setResult((previous) => ({ url, attempt, data: previous?.data, error: payload.error || fallbackError }));
        }
      } catch {
        if (!controller.signal.aborted) {
          setResult((previous) => ({ url, attempt, data: previous?.data, error: fallbackError }));
        }
      }
    }

    load();
    return () => controller.abort();
  }, [url, attempt, fallbackError]);

  const ready = result?.url === url && result.attempt === attempt;

  return {
    data: result?.data,
    error: ready ? result.error : null,
    loading: !ready,
    retry: () => setAttempt((value) => value + 1),
  };
}
