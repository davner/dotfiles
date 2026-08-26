<Toast ref={toast} />
<Button type="button" icon="pi pi-search" label="Search" onClick={(e) => op.current.toggle(e)} />
{selectedProductContent}
<OverlayPanel ref={op} showCloseIcon>
    <DataTable value={products} selectionMode="single" paginator rows={5} selection={selectedProduct} onSelectionChange={(e) => setSelectedProduct(e.value)}>
        <Column field="name" header="Name" sortable style={{minWidth: '12rem'}} />
        <Column header="Image" body={imageBody} />
        <Column field="price" header="Price" sortable body={priceBody} style={{minWidth: '8rem'}} />
    </DataTable>
</OverlayPanel>
