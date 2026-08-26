<TreeTable value={nodes} header={header} tableStyle={{ minWidth: '50rem' }}>
    <Column key="name" field="name" header="Name" expander />
    {visibleColumns.map((col) => (
        <Column key={col.field} field={col.field} header={col.header} />
    ))}
</TreeTable>
