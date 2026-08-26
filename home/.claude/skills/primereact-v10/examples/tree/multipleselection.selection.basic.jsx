<div className="flex align-items-center mb-4 gap-2">
    <InputSwitch inputId="input-metakey" checked={metaKey} onChange={(e) => setMetaKey(e.value)} />
    <label htmlFor="input-metakey">MetaKey</label>
</div>
<Tree value={nodes} metaKeySelection={metaKey} selectionMode="multiple" selectionKeys={selectedKeys} 
    onSelectionChange={(e) => setSelectedKeys(e.value)} className="w-full md:w-30rem" />
