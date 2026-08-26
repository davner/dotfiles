<DataTable value={products} expandedRows={expandedRows} onRowToggle={(e) => setExpandedRows(e.data)}
        onRowExpand={onRowExpand} onRowCollapse={onRowCollapse} rowExpansionTemplate={rowExpansionTemplate}
        dataKey="id" header={header} tableStyle={{ minWidth: '60rem' }}>
    <Column expander={allowExpansion} style={{ width: '5rem' }} />
    <Column field="name" header="Name" sortable />
    <Column header="Image" body={imageBodyTemplate} />
    <Column field="price" header="Price" sortable body={priceBodyTemplate} />
    <Column field="category" header="Category" sortable />
    <Column field="rating" header="Reviews" sortable body={ratingBodyTemplate} />
    <Column field="inventoryStatus" header="Status" sortable body={statusBodyTemplate} />
</DataTable>
