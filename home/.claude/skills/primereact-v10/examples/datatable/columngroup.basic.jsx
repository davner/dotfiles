<DataTable value={sales} headerColumnGroup={headerGroup} footerColumnGroup={footerGroup} tableStyle={{ minWidth: '50rem' }}>
    <Column field="product" />
    <Column field="lastYearSale" body={lastYearSaleBodyTemplate} />
    <Column field="thisYearSale" body={thisYearSaleBodyTemplate} />
    <Column field="lastYearProfit" body={lastYearProfitBodyTemplate} />
    <Column field="thisYearProfit" body={thisYearProfitBodyTemplate} />
</DataTable>
