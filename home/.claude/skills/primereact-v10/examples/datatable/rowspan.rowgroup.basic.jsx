<DataTable value={customers} rowGroupMode="rowspan" groupRowsBy="representative.name"
        sortMode="single" sortField="representative.name" sortOrder={1} tableStyle={{ minWidth: '50rem' }}>
    <Column header="#" headerStyle={{ width: '3rem' }} body={(data, options) => options.rowIndex + 1}></Column>
    <Column field="representative.name" header="Representative" body={representativeBodyTemplate} style={{ minWidth: '200px' }}></Column>
    <Column field="name" header="Name" style={{ minWidth: '200px' }}></Column>
    <Column field="country" header="Country" body={countryBodyTemplate} style={{ minWidth: '150px' }}></Column>
    <Column field="company" header="Company" style={{ minWidth: '200px' }}></Column>
    <Column field="status" header="Status" body={statusBodyTemplate} style={{ minWidth: '100px' }}></Column>
    <Column field="date" header="Date" style={{ minWidth: '100px' }}></Column>
</DataTable>
