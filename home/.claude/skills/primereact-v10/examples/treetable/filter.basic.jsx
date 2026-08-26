<SelectButton value={filterMode} onChange={(e) => setFilterMode(e.value)} options={filterOptions} />

<TreeTable value={nodes} globalFilter={globalFilter} header={header} filterMode={filterMode} tableStyle={{ minWidth: '50rem' }}>
    <Column field="name" header="Name" expander filter filterPlaceholder="Filter by name"></Column>
    <Column field="size" header="Size" filter filterPlaceholder="Filter by size"></Column>
    <Column field="type" header="Type" filter filterPlaceholder="Filter by type"></Column>
</TreeTable>
