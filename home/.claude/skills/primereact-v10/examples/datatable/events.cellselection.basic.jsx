<Toast ref={toast} />

<DataTable value={products} cellSelection selectionMode="single" selection={selectedCell}
        onSelectionChange={(e) => setSelectedCell(e.value)} metaKeySelection={false}
        onCellSelect={onCellSelect} onCellUnselect={onCellUnselect} tableStyle={{ minWidth: '50rem' }}>
    <Column field="code" header="Code"></Column>
    <Column field="name" header="Name"></Column>
    <Column field="category" header="Category"></Column>
    <Column field="quantity" header="Quantity"></Column>
</DataTable>
