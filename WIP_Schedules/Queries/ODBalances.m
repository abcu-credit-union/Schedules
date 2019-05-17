let
    queryDate = Text.From(BalanceDate[Date]{0}),
    SQL =
"SELECT
    ACCT.BRANCHORGNBR ""Branch"",
    ACCT.MJACCTTYPCD ""Major Code"",
    ACCT.CURRMIACCTTYPCD ""Minor Code"",
    SUM(WH_ACCTDEPOSIT.LIMITODBAL) ""Authorized OD"",
    SUM(WH_ACCTDEPOSIT.ODEXCESSBAL) ""Unauthorized OD""
FROM ACCT
INNER JOIN WH_ACCTDEPOSIT
    ON ACCT.ACCTNBR = WH_ACCTDEPOSIT.ACCTNBR
WHERE
    WH_ACCTDEPOSIT.EFFDATE = TO_DATE('"&queryDate&"', 'MM/DD/YYYY')
    AND ACCT.CURRACCTSTATCD NOT IN ('CLS', 'CO')
GROUP BY
    ACCT.BRANCHORGNBR,
    ACCT.MJACCTTYPCD,
    ACCT.CURRMIACCTTYPCD",

    BBSource = Oracle.Database("BCUDatabase", [Query = ""&SQL&""]),
    CCSource = Oracle.Database("RCCUDatabase", [Query = ""&SQL&""]),
    ABCUSource = Table.Combine({BBSource, CCSource})

in
    ABCUSource
