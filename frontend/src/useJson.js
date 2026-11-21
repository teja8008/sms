import { useEffect, useState } from "react";

export default function useJson(url, fallbackError) {
  const [result, setResult] = useState(null);
  const [attempt, setAttempt] = useState(0);
  const key = `${url}:${attempt}`;

  useEffect(() => {
    const controller = new AbortController();

    async function load() {
      try {
        const response = await fetch(url, { signal: controller.signal });
        const payload = await response.json();
        if (controller.signal.aborted) return;

        if (response.ok) {
          setResult({ key, data: payload });
        } else {
          setResult((previous) => ({ key, data: previous?.data, error: payload.error || fallbackError }));
        }
      } catch {
        if (!controller.signal.aborted) {
          setResult((previous) => ({ key, data: previous?.data, error: fallbackError }));
        }
      }
    }

    load();
    return () => controller.abort();
  }, [url, key, fallbackError]);

  const ready = result?.key === key;

  return {
    data: result?.data,
    error: ready ? result.error : null,
    loading: !ready,
    retry: () => setAttempt((value) => value + 1),
  };
}
