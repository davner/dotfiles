<div className="flex flex-wrap gap-2 mb-4">
    <Button type="button" icon="pi pi-plus" label="Expand All" onClick={expandAll} />
    <Button type="button" icon="pi pi-minus" label="Collapse All" onClick={collapseAll} />
</div>

<Tree value={nodes} expandedKeys={expandedKeys} onToggle={(e) => setExpandedKeys(e.value)} className="w-full md:w-30rem" />
