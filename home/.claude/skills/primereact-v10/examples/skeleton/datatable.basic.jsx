<DataTable value={items} className="p-datatable-striped">
    <Column field="code" header="Code" style={{ width: '25%' }} body={<Skeleton />}></Column>
    <Column field="name" header="Name" style={{ width: '25%' }} body={<Skeleton />}></Column>
    <Column field="category" header="Category" style={{ width: '25%' }} body={<Skeleton />}></Column>
    <Column field="quantity" header="Quantity" style={{ width: '25%' }} body={<Skeleton />}></Column>
</DataTable>
