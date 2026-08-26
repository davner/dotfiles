<InputSwitch checked={metaKey} onChange={(e) => setMetaKey(e.value)} />

<DataTable value={products} cellSelection selectionMode="multiple" selection={selectedCells}
        onSelectionChange={(e) => setSelectedCells(e.value)}
        metaKeySelection={metaKey} dragSelection tableStyle={{ minWidth: '50rem' }}>
    <Column field="code" header="Code"></Column>
    <Column field="name" header="Name"></Column>
    <Column field="category" header="Category"></Column>
    <Column field="quantity" header="Quantity"></Column>
</DataTable>
