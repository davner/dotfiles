<DataTable value={cars} scrollable scrollHeight="400px" virtualScrollerOptions={{ itemSize: 46 }} tableStyle={{ minWidth: '50rem' }}>
    <Column field="id" header="Id" style={{ width: '20%' }}></Column>
    <Column field="vin" header="Vin" style={{ width: '20%' }}></Column>
    <Column field="year" header="Year" style={{ width: '20%' }}></Column>
    <Column field="brand" header="Brand" style={{ width: '20%' }}></Column>
    <Column field="color" header="Color" style={{ width: '20%' }}></Column>
</DataTable>
