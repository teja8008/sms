import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig(({ command }) => ({
  plugins: [react()],
  base: command === "build" ? "/frontend/" : "/",
  server: {
    strictPort: true,
    proxy: {
      "/api": "http://127.0.0.1:3000",
    },
  },
  build: {
    outDir: "../public/frontend",
    emptyOutDir: true,
    license: { fileName: "licenses.txt" },
  },
}));
