let
    queryDate = Text.From(BalanceDate[Date]{0}),
    SQL =
"SELECT
    GLACCTPROOFHIST.EFFDATE ""Date"",
    GLACCTTITLE.GLACCTTITLENAME ""GL Name"",
    SUBSTR(GLACCT.XREFGLACCTNBR, 0, 8) ""GL Number"",
    SUBSTR(GLACCT.XREFGLACCTNBR, -3) AS ""Branch"",
    MJMIACCTGL.MJACCTTYPCD ""Major Code"",
    MJMIACCTGL.MIACCTTYPCD ""Minor Code"",
    ABS(GLACCTPROOFHIST.GLACCTBAL) ""DNA Balance""
FROM GLACCTPROOFHIST
INNER JOIN GLACCT
	ON GLACCTPROOFHIST.GLACCTNBR = GLACCT.GLACCTNBR
INNER JOIN GLACCTTITLE
	ON GLACCT.GLACCTTITLENBR = GLACCTTITLE.GLACCTTITLENBR
INNER JOIN MJMIACCTGL
    ON GLACCT.GLACCTTITLENBR = MJMIACCTGL.GLACCTTITLENBR
WHERE
	GLACCTPROOFHIST.EFFDATE = TO_DATE('"&queryDate&"', 'MM/DD/YYYY')
    AND GLACCT.PROOFYN = 'Y'",

    BBSource = Oracle.Database("BCUDatabase", [Query = ""&SQL&""]),
    CCSource = Oracle.Database("RCCUDatabase", [Query = ""&SQL&""]),
    ABCUSource = Table.Combine({BBSource, CCSource}),

    #"Changed Type" = Table.TransformColumnTypes(ABCUSource,
        {{"GL Number", type number},
        {"Branch", type number},
        {"Date", type date}}),

    #"Sorted Results" = Table.Sort(#"Changed Type",
        {{"GL Number", Order.Ascending},
        {"Branch", Order.Ascending}}),

    #"Added Month" = Table.AddColumn(#"Sorted Results", "Month",
        each Date.Month(Date.From([Date])), type number),
    #"Added Year" = Table.AddColumn(#"Added Month", "Year",
        each Date.Year(Date.From([Date])), type number),

    #"Added OD Balances" = Table.ExpandTableColumn(
        Table.NestedJoin(#"Added Year", {"Major Code", "Minor Code", "Branch"}, ODBalances, {"Major Code", "Minor Code", "Branch"}, "OD", JoinKind.LeftOuter),
    "OD", {"Authorized OD", "Unauthorized OD"}, {"DNA Authorized OD", "DNA Unauthorized OD"}),

    #"Replaced Value" = Table.ReplaceValue(#"Added OD Balances",null,0,Replacer.ReplaceValue,
        {"DNA Authorized OD", "DNA Unauthorized OD"}),

    #"Added FAS Balances" = Table.ExpandTableColumn(
        Table.NestedJoin(#"Replaced Value", {"Year", "Month", "GL Number", "Branch"},
            Table.SelectRows(FASQuery,
                each [Source DB] = 332),
            {"Year", "Month Index", "GL Number", "Branch"}, "FAS", JoinKind.LeftOuter),
    "FAS", {"YTD Balance", "FSMS Line"}, {"FAS Balance", "FSMS Line"}),

    #"Added Outage Column" = Table.AddColumn(#"Added FAS Balances", "Outage",
        each if [GL Number] = 20000999 then
            [FAS Balance] - [DNA Balance] + ([DNA Authorized OD] + [DNA Unauthorized OD])
        else if Text.Contains([GL Name], "Demand Deposit") or Text.Range([GL Name], 0, 3) = "DDA" then
            [FAS Balance] - [DNA Balance] - ([DNA Authorized OD] + [DNA Unauthorized OD])
        else [FAS Balance] - [DNA Balance], type number),

    #"Grouped Results" = Table.Group(#"Added Outage Column", {"FSMS Line", "Date", "GL Name", "GL Number", "Branch"},
        {{"DNA Balance", each List.First([DNA Balance]), type number},
        {"FAS Balance", each List.First([FAS Balance]), type number},
        {"Authorized OD", each List.First([DNA Authorized OD]), type number},
        {"Unauthorized OD", each List.First([DNA Unauthorized OD]), type number},
        {"Outage", each List.First([Outage]), type number}})

    /*#"Removed Extra Columns" = Table.RemoveColumns(#"Added Outage Column",
        {"Month", "Year"}),

    #"Reordered Columns" = Table.ReorderColumns(#"Removed Extra Columns",
        {"Date", "FSMS Line", "GL Name", "GL Number", "Branch", "DNA Balance", "FAS Balance", "Outage"})*/
in
    #"Grouped Results"
