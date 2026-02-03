// Entry point for the build script in your package.json
import React from "react";
import { createRoot } from "react-dom/client";
import RequestsPanel from "./components/RequestsPanel";

// Mount React component if container exists
document.addEventListener("DOMContentLoaded", () => {
  const container = document.getElementById("nutritionist-requests-app");

  if (container) {
    const nutritionistId = container.dataset.nutritionistId;
    const apiUrl = container.dataset.apiUrl;

    const root = createRoot(container);
    root.render(
      <RequestsPanel nutritionistId={nutritionistId} apiUrl={apiUrl} />
    );
  }
});
