<DataTable value={products} header={header} tableStyle={{ minWidth: '50rem' }}>
    <Column field="code" header="Code" />
    {visibleColumns.map((col) => (
        <Column key={col.field} field={col.field} header={col.header} />
    ))}
</DataTable>
