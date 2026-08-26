<ContextMenu model={menu} ref={cm} onHide={() => setSelectedNodeKey(null)} />
<TreeTable value={nodes} expandedKeys={expandedKeys} onToggle={(e) => setExpandedKeys(e.value)} contextMenuSelectionKey={selectedNodeKey}
    onContextMenuSelectionChange={(event) => setSelectedNodeKey(event.value)} onContextMenu={(event) => cm.current.show(event.originalEvent)} tableStyle={{ minWidth: '50rem' }}>
    <Column field="name" header="Name" expander></Column>
    <Column field="size" header="Size"></Column>
    <Column field="type" header="Type"></Column>
</TreeTable>
