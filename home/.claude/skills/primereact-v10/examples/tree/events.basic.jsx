<Toast ref={toast} />
<Tree value={nodes} selectionMode="single" selectionKeys={selectedNodeKey} onSelectionChange={(e) => setSelectedNodeKey(e.value)} 
    onExpand={onExpand} onCollapse={onCollapse} onSelect={onSelect} onUnselect={onUnselect} className="w-full md:w-30rem" />
