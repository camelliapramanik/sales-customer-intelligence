# Publish as a GitHub portfolio

Repository: [camelliapramanik/sales-customer-intelligence](https://github.com/camelliapramanik/sales-customer-intelligence).

This guide records the repository settings and explains how to publish a copy or update the portfolio.

## Suggested repository details

**Name:** `sales-customer-intelligence`

**Description:** SQL Server and Power BI portfolio analyzing AdventureWorks sales, customer activity, product profitability, and territory performance with a star schema and 55 DAX measures.

**Topics:** `power-bi`, `sql-server`, `dax`, `power-query`, `business-intelligence`, `data-analytics`, `adventureworks`, `portfolio`, `star-schema`

## Publish your own copy with Git

Create an empty repository in your GitHub account. From this project folder, run the following commands, replacing the remote URL with the one GitHub provides:

```powershell
git init -b main
git add README.md .gitignore .gitattributes SQL 'Power BI' DAX data docs tools
git status --short
git diff --cached --stat
git commit -m "Add Sales and Customer Intelligence portfolio"
git remote add origin https://github.com/YOUR-USERNAME/sales-customer-intelligence.git
git push -u origin main
```

## Update the existing portfolio

After reviewing changes, stage the intended files, commit, and push to the configured `origin`:

```powershell
git status --short
git add README.md .gitignore .gitattributes SQL 'Power BI' DAX data docs tools
git diff --cached --stat
git commit -m "Update portfolio documentation and analysis"
git push
```

The explicit staging list omits the database backup and temporary preparation files. `.gitignore` also excludes `*.bak`, local model caches, credentials files, and `.portfolio-work/`. Keep those exclusions when using GitHub Desktop or another Git client. The original PBIX is approximately 3.3 MiB and is included as the downloadable report artifact.

## Publication review

- Confirm the README, diagrams, links, DAX, SQL, and Power Query files render correctly on GitHub.
- Keep the PBIX and all relative folder names together so links work.
- When refreshing against another data source, inspect imported content before sharing the new PBIX.
- The supplied PBIX includes sample records, a `localhost` query source, and embedded cloud report/dataset identifiers. Those identifiers are not access credentials; the original package was retained without binary editing.
- Choose a license for your original work if you want to grant reuse rights. Preserve the separate Microsoft sample-data attribution.
- Pin the published repository to your GitHub profile and use the description above in the repository's About section.

## Optional visual gallery

Export the four report pages from Power BI Desktop, then add genuine screenshots under `docs/assets/` and embed them in the README. Check that totals and slicer selections are readable and that screenshots match the published PBIX. Do not label the editorial banner as a dashboard screenshot.
