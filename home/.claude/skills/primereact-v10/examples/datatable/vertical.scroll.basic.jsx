<DataTable value={customers} scrollable scrollHeight="400px" style={{ minWidth: '50rem' }}>
    <Column field="name" header="Name"></Column>
    <Column field="country.name" header="Country"></Column>
    <Column field="representative.name" header="Representative"></Column>
    <Column field="company" header="Company"></Column>
</DataTable>
