let
    Source = Sql.Databases("localhost"),
    AdventureWorks2025 = Source{[Name="AdventureWorks2025"]}[Data],
    analytics_vw_DimProduct = AdventureWorks2025{[Schema="analytics",Item="vw_DimProduct"]}[Data]
in
    analytics_vw_DimProduct
