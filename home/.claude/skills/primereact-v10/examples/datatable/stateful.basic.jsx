<DataTable value={customers} paginator rows={5} header={header} filters={filters} onFilter={(e) => setFilters(e.filters)}
        selection={selectedCustomer} onSelectionChange={(e) => setSelectedCustomer(e.value)} selectionMode="single" dataKey="id"
        stateStorage="session" stateKey="dt-state-demo-local" emptyMessage="No customers found." tableStyle={{ minWidth: '50rem' }}>
    <Column field="name" header="Name" sortable filter filterPlaceholder="Search" style={{ width: '25%' }}></Column>
    <Column header="Country" body={countryBodyTemplate} sortable sortField="country.name" filter filterField="country.name" filterPlaceholder="Search" style={{ width: '25%' }}></Column>
    <Column header="Agent" body={representativeBodyTemplate} sortable sortField="representative.name" filter filterField="representative"
        showFilterMatchModes={false} filterElement={representativeFilterTemplate} filterMenuStyle={{ width: '14rem' }} style={{ width: '25%' }} ></Column>
    <Column field="status" header="Status" body={statusBodyTemplate} sortable filter filterElement={statusFilterTemplate} filterMenuStyle={{ width: '14rem' }} style={{ width: '25%' }}></Column>
</DataTable>
