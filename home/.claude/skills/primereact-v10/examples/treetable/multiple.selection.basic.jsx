<InputSwitch checked={metaKey} onChange={(e) => setMetaKey(e.value)} />

<TreeTable value={nodes} selectionMode="multiple" selectionKeys={selectedNodeKeys}
        onSelectionChange={(e) => setSelectedNodeKeys(e.value)} metaKeySelection={metaKey} tableStyle={{ minWidth: '50rem' }}>
    <Column field="name" header="Name" expander></Column>
    <Column field="size" header="Size"></Column>
    <Column field="type" header="Type"></Column>
</TreeTable>
