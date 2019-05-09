let
    SQL =
"SELECT
    ACCT.BRANCHORGNBR ""Branch"",
    WH_ACCTCOMMON.EFFDATE ""Date"",
    WH_ACCTCOMMON.MJACCTTYPCD ""Major Type"",
    WH_ACCTCOMMON.CURRMIACCTTYPCD ""Minor Type"",
    WH_ACCTCOMMON.PRODUCT ""Product"",
    SUM(WH_ACCTCOMMON.NOTEBAL) ""Balance"",
    SUM(WH_ACCTLOAN.NOTEACCRUEDINT) ""Accrued Interest"",
    SUM(WH_ACCTLOAN.LIPBAL) ""LIP Balance""
FROM WH_ACCTCOMMON
INNER JOIN WH_ACCTLOAN
    ON WH_ACCTCOMMON.ACCTNBR = WH_ACCTLOAN.ACCTNBR
    AND WH_ACCTCOMMON.EFFDATE = WH_ACCTLOAN.EFFDATE
INNER JOIN ACCT
    ON WH_ACCTCOMMON.ACCTNBR = ACCT.ACCTNBR
WHERE
    WH_ACCTCOMMON.EFFDATE >= TRUNC(ADD_MONTHS(CURRENT_DATE, -12))
    AND WH_ACCTCOMMON.CURRACCTSTATCD NOT IN ('CLS', 'CO')
    AND WH_ACCTCOMMON.MONTHENDYN = 'Y'
GROUP BY
    ACCT.BRANCHORGNBR,
    WH_ACCTCOMMON.EFFDATE,
    WH_ACCTCOMMON.MJACCTTYPCD,
    WH_ACCTCOMMON.CURRMIACCTTYPCD,
    WH_ACCTCOMMON.PRODUCT",

    BBSource = Table.AddColumn(
        Oracle.Database("BCUDatabase", [Query = ""&SQL&""]),
    "Source DB", each "Beaumont"),
    CCSource = Table.AddColumn(
        Oracle.Database("RCCUDatabase", [Query = ""&SQL&""]),
    "Source DB", each "City Centre"),
    ABCUSource = Table.Combine({BBSource, CCSource}),

    #"Sorted Results" = Table.Sort(ABCUSource,
        {
            {"Date", Order.Ascending},
            {"Major Type", Order.Ascending},
            {"Minor Type", Order.Ascending},
            {"Branch", Order.Ascending}
        })

in
    #"Sorted Results"
