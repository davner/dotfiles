<div className="card flex flex-column align-items-center gap-3">
    <Button type="button" label="Toggle All" text onClick={() => toggleAll()} />
    <PanelMenu model={items} expandedKeys={expandedKeys} onExpandedKeysChange={setExpandedKeys} className="w-full md:w-20rem" multiple />
</div>  
