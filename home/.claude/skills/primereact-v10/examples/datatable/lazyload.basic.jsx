<DataTable value={customers} lazy filterDisplay="row" dataKey="id" paginator
        first={lazyState.first} rows={10} totalRecords={totalRecords} onPage={onPage}
        onSort={onSort} sortField={lazyState.sortField} sortOrder={lazyState.sortOrder}
        onFilter={onFilter} filters={lazyState.filters} loading={loading} tableStyle={{ minWidth: '75rem' }}
        selection={selectedCustomers} onSelectionChange={onSelectionChange} selectAll={selectAll} onSelectAllChange={onSelectAllChange}>
    <Column selectionMode="multiple" headerStyle={{ width: '3rem' }} />
    <Column field="name" header="Name" sortable filter filterPlaceholder="Search" />
    <Column field="country.name" sortable header="Country" filterField="country.name" body={countryBodyTemplate} filter filterPlaceholder="Search" />
    <Column field="company" sortable filter header="Company" filterPlaceholder="Search" />
    <Column field="representative.name" header="Representative" body={representativeBodyTemplate} filter filterPlaceholder="Search" />
</DataTable>
