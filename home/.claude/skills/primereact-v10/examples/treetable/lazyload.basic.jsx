<TreeTable value={nodes} lazy paginator totalRecords={totalRecords}
        first={first} rows={rows} onPage={onPage} onExpand={onExpand} loading={loading} tableStyle={{ minWidth: '50rem' }}>
    <Column field="name" header="Name" expander></Column>
    <Column field="size" header="Size"></Column>
    <Column field="type" header="Type"></Column>
</TreeTable>
