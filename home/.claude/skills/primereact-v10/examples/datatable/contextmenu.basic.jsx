<Toast ref={toast} />
<ContextMenu model={menuModel} ref={cm} onHide={() => setSelectedProduct(null)} />
<DataTable value={products} onContextMenu={(e) => cm.current.show(e.originalEvent)}
        contextMenuSelection={selectedProduct} onContextMenuSelectionChange={(e) => setSelectedProduct(e.value)} tableStyle={{ minWidth: '50rem' }}>
    <Column field="code" header="Code"></Column>
    <Column field="name" header="Name"></Column>
    <Column field="category" header="Category"></Column>
    <Column field="price" header="Price" body={priceBodyTemplate} />
</DataTable>
