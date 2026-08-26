<TreeSelect value={selectedNodeKey} onChange={(e) => setSelectedNodeKey(e.value)} options={nodes} 
    className="md:w-20rem w-full" placeholder="Select Item"
    expandedKeys={expandedKeys} onToggle={(e) => setExpandedKeys(e.value)} panelHeaderTemplate={headerTemplate}></TreeSelect>
