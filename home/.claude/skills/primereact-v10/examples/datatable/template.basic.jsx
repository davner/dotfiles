<DataTable value={products} header={header} footer={footer} tableStyle={{ minWidth: '60rem' }}>
    <Column field="name" header="Name"></Column>
    <Column header="Image" body={imageBodyTemplate}></Column>
    <Column field="price" header="Price" body={priceBodyTemplate}></Column>
    <Column field="category" header="Category"></Column>
    <Column field="rating" header="Reviews" body={ratingBodyTemplate}></Column>
    <Column header="Status" body={statusBodyTemplate}></Column>
</DataTable>
