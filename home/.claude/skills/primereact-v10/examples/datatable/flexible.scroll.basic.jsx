<Button label="Show" icon="pi pi-external-link" onClick={() => setDialogVisible(true)} />
<Dialog header="Flex Scroll" visible={dialogVisible} style={{ width: '75vw' }} maximizable
        modal contentStyle={{ height: '300px' }} onHide={() => setDialogVisible(false)} footer={dialogFooterTemplate}>
    <DataTable value={customers} scrollable scrollHeight="flex" tableStyle={{ minWidth: '50rem' }}>
        <Column field="name" header="Name"></Column>
        <Column field="country.name" header="Country"></Column>
        <Column field="representative.name" header="Representative"></Column>
        <Column field="company" header="Company"></Column>
    </DataTable>
</Dialog>
