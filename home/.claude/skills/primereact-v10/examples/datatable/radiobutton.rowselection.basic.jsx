<InputSwitch checked={rowClick} onChange={(e) => setRowClick(e.value)} />

<DataTable value={products} selectionMode={rowClick ? null : 'radiobutton'} selection={selectedProduct} onSelectionChange={(e) => setSelectedProduct(e.value)} dataKey="id" tableStyle={{ minWidth: '50rem' }}>
    <Column selectionMode="single" headerStyle={{ width: '3rem' }}></Column>
    <Column field="code" header="Code"></Column>
    <Column field="name" header="Name"></Column>
    <Column field="category" header="Category"></Column>
    <Column field="quantity" header="Quantity"></Column>
</DataTable>
