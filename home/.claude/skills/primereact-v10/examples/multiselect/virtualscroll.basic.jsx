<MultiSelect
    value={selectedItems}
    options={items}
    onChange={(e) => {
        setSelectedItems(e.value);
        setSelectAll(e.value.length === items.length);
    }}
    selectAll={selectAll}
    onSelectAll={(e) => {
        setSelectedItems(e.checked ? [] : items.map((item) => item.value));
        setSelectAll(!e.checked);
    }}
    virtualScrollerOptions={{ itemSize: 43 }}
    maxSelectedLabels={3}
    placeholder="Select Items"
    className="w-full md:w-20rem"
/>
