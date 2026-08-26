<Toast ref={toast} />

<ContextMenu model={menu} ref={cm} />

<Tree value={nodes} expandedKeys={expandedKeys} onToggle={(e) => setExpandedKeys(e.value)} 
    contextMenuSelectionKey={selectedNodeKey} onContextMenuSelectionChange={(e) => setSelectedNodeKey(e.value)} 
    onContextMenu={(e) => cm.current.show(e.originalEvent)} className="w-full md:w-30rem" />
