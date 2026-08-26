<DataTable value={products} reorderableColumns reorderableRows onRowReorder={(e) => setProducts(e.value)} tableStyle={{ minWidth: '50rem' }}>
    <Column rowReorder style={{ width: '3rem' }} />
    {dynamicColumns}
</DataTable>
