<DataTable value={customers} rowGroupMode="subheader" groupRowsBy="representative.name"
    sortMode="single" sortField="representative.name" sortOrder={1}
    expandableRowGroups expandedRows={expandedRows} onRowToggle={(e) => setExpandedRows(e.data)}
    rowGroupHeaderTemplate={headerTemplate} rowGroupFooterTemplate={footerTemplate} tableStyle={{ minWidth: '50rem' }}>
    <Column field="name" header="Name" style={{ width: '20%' }}></Column>
    <Column field="country" header="Country" body={countryBodyTemplate} style={{ width: '20%' }}></Column>
    <Column field="company" header="Company" style={{ width: '20%' }}></Column>
    <Column field="status" header="Status" body={statusBodyTemplate} style={{ width: '20%' }}></Column>
    <Column field="date" header="Date" style={{ width: '20%' }}></Column>
</DataTable>
