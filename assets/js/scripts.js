document.querySelectorAll("[data-sortable-table]").forEach((table) => {
  const tbody = table.querySelector("tbody");
  const buttons = table.querySelectorAll("[data-sort-key]");

  buttons.forEach((button) => {
    button.addEventListener("click", () => {
      const key = button.dataset.sortKey;
      const current = table.dataset.sortKey === key ? table.dataset.sortDirection : "desc";
      const direction = current === "asc" ? "desc" : "asc";
      const multiplier = direction === "asc" ? 1 : -1;
      const rows = Array.from(tbody.querySelectorAll("tr"));
      const parentRows = rows.filter((row) => row.dataset.name === "../");
      const sortableRows = rows.filter((row) => row.dataset.name !== "../");

      sortableRows.sort((left, right) => {
        if (key === "size" || key === "date") {
          return (Number(left.dataset[key]) - Number(right.dataset[key])) * multiplier;
        }

        return left.dataset[key].localeCompare(right.dataset[key], undefined, {
          numeric: true,
          sensitivity: "base"
        }) * multiplier;
      });

      table.dataset.sortKey = key;
      table.dataset.sortDirection = direction;

      buttons.forEach((otherButton) => {
        otherButton.removeAttribute("aria-sort");
      });
      button.setAttribute("aria-sort", direction === "asc" ? "ascending" : "descending");

      tbody.replaceChildren(...parentRows, ...sortableRows);
    });
  });
});
