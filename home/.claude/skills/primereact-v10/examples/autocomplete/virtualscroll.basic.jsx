<AutoComplete value={selectedItem} suggestions={filteredItems} completeMethod={searchItems}
    virtualScrollerOptions={{ itemSize: 38 }} field="label" dropdown onChange={(e) => setSelectedItem(e.value)} />
