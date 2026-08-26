<ToggleButton checked={balanceFrozen} onChange={(e) => setBalanceFrozen(e.value)}
    onIcon="pi pi-lock" offIcon="pi pi-lock-open" onLabel="Balance" offLabel="Balance" />
<DataTable value={customers} scrollable scrollHeight="400px" className="mt-4">
    <Column field="name" header="Name" style={{ minWidth: '200px' }} frozen className="font-bold"></Column>
    <Column field="id" header="Id" style={{ minWidth: '100px' }}></Column>
    <Column field="name" header="Name" style={{ minWidth: '200px' }}></Column>
    <Column field="country.name" header="Country" style={{ minWidth: '200px' }}></Column>
    <Column field="date" header="Date" style={{ minWidth: '200px' }}></Column>
    <Column field="company" header="Company" style={{ minWidth: '200px' }}></Column>
    <Column field="status" header="Status" style={{ minWidth: '200px' }}></Column>
    <Column field="activity" header="Activity" style={{ minWidth: '200px' }}></Column>
    <Column field="representative.name" header="Representative" style={{ minWidth: '200px' }}></Column>
    <Column field="balance" header="Balance" body={balanceTemplate} style={{ minWidth: '200px' }} alignFrozen="right" frozen={balanceFrozen}></Column>
</DataTable>
