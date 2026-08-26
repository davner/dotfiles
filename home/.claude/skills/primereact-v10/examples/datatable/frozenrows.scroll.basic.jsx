<DataTable value={customers} frozenValue={lockedCustomers} scrollable scrollHeight="400px" tableStyle={{ minWidth: '50rem' }}>
    <Column field="name" header="Name"></Column>
    <Column field="country.name" header="Country"></Column>
    <Column field="representative.name" header="Representative"></Column>
    <Column field="status" header="Status"></Column>
    <Column style={{ flex: '0 0 4rem' }} body={lockTemplate}></Column>
</DataTable>
