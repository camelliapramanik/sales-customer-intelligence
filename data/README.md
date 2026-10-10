# Data source and provenance

The source is **Microsoft AdventureWorks2025**, the relational OLTP sample database for a fictional business. The project reads sales orders, order details, customers, people, stores, products, cost history, salespeople, and territories.

- [Official download and restore instructions](https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure)
- [Microsoft SQL Server samples repository](https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/adventure-works)
- [AdventureWorks releases](https://github.com/microsoft/sql-server-samples/releases/tag/adventureworks)

Use **AdventureWorks2025.bak**, not AdventureWorksDW or AdventureWorksLT: the SQL depends on the OLTP `Sales`, `Production`, and `Person` schemas. Use a SQL Server version compatible with the backup; a newer-version backup cannot be restored to an older database engine.

## What is distributed

The PBIX contains imported sample records. The repository also contains aggregated reference results and extracted model/report metadata. Customer names and account fields originate from the sample data.

The local `AdventureWorks2025.bak` file is excluded by `.gitignore` and is not required in Git history. Download the backup from Microsoft to reproduce the source, then run the SQL analytics pipeline. Any local changes to the existing backup were not independently verified during portfolio preparation.

The reference period observed in the PBIX is **May 30, 2022 through June 29, 2025**. The database's release name is not the reporting period. The reference totals describe the imported snapshot; a changed source or refreshed model may produce different values.

## Attribution and reuse

Microsoft provides the sample data. Refer to its source repository for applicable license terms. No new license grant for Microsoft's data is implied, and no repository-wide license has been selected for the author's original work.
