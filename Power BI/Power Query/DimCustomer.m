let
    Source = Sql.Databases("localhost"),
    AdventureWorks2025 = Source{[Name="AdventureWorks2025"]}[Data],
    analytics_vw_DimCustomer = AdventureWorks2025{[Schema="analytics",Item="vw_DimCustomer"]}[Data],
    #"Changed Type" = Table.TransformColumnTypes(analytics_vw_DimCustomer,{{"CustomerID", Int64.Type}})
in
    #"Changed Type"
