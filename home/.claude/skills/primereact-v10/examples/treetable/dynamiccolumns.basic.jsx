<TreeTable value={nodes} tableStyle={{ minWidth: '50rem' }}>
    {columns.map((col, i) => (
        <Column key={col.field} field={col.field} header={col.header} expander={col.expander} />
    ))}
</TreeTable>
