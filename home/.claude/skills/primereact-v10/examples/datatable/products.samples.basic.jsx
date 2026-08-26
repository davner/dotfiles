<Toolbar className="mb-4" left={leftToolbarTemplate} right={rightToolbarTemplate}></Toolbar>
<DataTable ref={dt} value={products} selection={selectedProducts} onSelectionChange={(e) => setSelectedProducts(e.value)}
        dataKey="id"  paginator rows={10} rowsPerPageOptions={[5, 10, 25]}
        paginatorTemplate="FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink CurrentPageReport RowsPerPageDropdown"
        currentPageReportTemplate="Showing {first} to {last} of {totalRecords} products" globalFilter={globalFilter} header={header}>
    <Column selectionMode="multiple" exportable={false}></Column>
    <Column field="code" header="Code" sortable style={{ minWidth: '12rem' }}></Column>
    <Column field="name" header="Name" sortable style={{ minWidth: '16rem' }}></Column>
    <Column field="image" header="Image" body={imageBodyTemplate}></Column>
    <Column field="price" header="Price" body={priceBodyTemplate} sortable style={{ minWidth: '8rem' }}></Column>
    <Column field="category" header="Category" sortable style={{ minWidth: '10rem' }}></Column>
    <Column field="rating" header="Reviews" body={ratingBodyTemplate} sortable style={{ minWidth: '12rem' }}></Column>
    <Column field="inventoryStatus" header="Status" body={statusBodyTemplate} sortable style={{ minWidth: '12rem' }}></Column>
    <Column body={actionBodyTemplate} exportable={false} style={{ minWidth: '12rem' }}></Column>
</DataTable>
