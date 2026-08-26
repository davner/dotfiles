<DataTable value={products} sortField="price" sortOrder={-1} tableStyle={{ minWidth: '50rem' }}>
    <Column field="code" header="Code" sortable style={{ width: '20%' }}></Column>
    <Column field="name" header="Name" sortable style={{ width: '20%' }}></Column>
    <Column field="price" header="Price" body={priceBodyTemplate} sortable style={{ width: '20%' }}></Column>
    <Column field="category" header="Category" sortable style={{ width: '20%' }}></Column>
    <Column field="quantity" header="Quantity" sortable style={{ width: '20%' }}></Column>
</DataTable>
