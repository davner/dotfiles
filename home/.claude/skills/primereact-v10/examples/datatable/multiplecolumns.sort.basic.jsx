<DataTable value={products} sortMode="multiple" tableStyle={{ minWidth: '50rem' }}>
    <Column field="code" header="Code" sortable style={{ width: '25%' }}></Column>
    <Column field="name" header="Name" sortable style={{ width: '25%' }}></Column>
    <Column field="category" header="Category" sortable style={{ width: '25%' }}></Column>
    <Column field="quantity" header="Quantity" sortable style={{ width: '25%' }}></Column>
</DataTable>
