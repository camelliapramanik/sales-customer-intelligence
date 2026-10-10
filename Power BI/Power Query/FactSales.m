let
    Source = Sql.Databases("localhost"),
    AdventureWorks2025 = Source{[Name="AdventureWorks2025"]}[Data],
    analytics_vw_FactSales = AdventureWorks2025{[Schema="analytics",Item="vw_FactSales"]}[Data],
    #"Changed Type" = Table.TransformColumnTypes(analytics_vw_FactSales,{{"Profit", Currency.Type}, {"TotalProductCost", Currency.Type}, {"SalesAmount", Currency.Type}, {"DiscountAmount", Currency.Type}, {"GrossSales", Currency.Type}, {"OrderQty", Int64.Type}})
in
    #"Changed Type"
