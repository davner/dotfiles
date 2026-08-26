<FloatLabel className="w-full md:w-20rem">
    <TreeSelect inputId="treeselect" value={selectedNodeKey} onChange={(e) => setSelectedNodeKey(e.value)} options={nodes}
        className="w-full"></TreeSelect>
    <label htmlFor="treeselect">TreeSelect</label>
</FloatLabel>
