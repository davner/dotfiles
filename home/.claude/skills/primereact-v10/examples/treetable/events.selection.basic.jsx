<TreeTable value={nodes} selectionMode="single" selectionKeys={selectedNodeKey}
        onSelectionChange={(e) => setSelectedNodeKey(e.value)} metaKeySelection={false}
        onSelect={onSelect} onUnselect={onUnselect} tableStyle={{ minWidth: '50rem' }}>
    <Column field="name" header="Name" expander></Column>
    <Column field="size" header="Size"></Column>
    <Column field="type" header="Type"></Column>
</TreeTable>
