let
    Source = Sql.Databases("localhost"),
    AdventureWorks2025 = Source{[Name="AdventureWorks2025"]}[Data],
    analytics_vw_DimTerritory = AdventureWorks2025{[Schema="analytics",Item="vw_DimTerritory"]}[Data]
in
    analytics_vw_DimTerritory
