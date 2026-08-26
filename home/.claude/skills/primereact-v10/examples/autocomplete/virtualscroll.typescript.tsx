import React, { useState } from "react";
import { AutoComplete, AutoCompleteCompleteEvent } from "primereact/autocomplete";

interface Item {
    label: string;
    value: number;
}

export default function VirtualScrollerDemo() {
    const [selectedItem, setSelectedItem] = useState<Item>(null);
    const [filteredItems, setFilteredItems] = useState<Item[]>(null);
    const items = Array.from({ length: 100000 }).map((_, i) => ({ label: `Item #${i}`, value: i }));

    const searchItems = (event: AutoCompleteCompleteEvent) => {
        //in a real application, make a request to a remote url with the query and return filtered results, for demo purposes we filter at client side
        let query = event.query;
        let _filteredItems = [];

        for(let i = 0; i < items.length; i++) {
            let item = items[i];
            if (item.label.toLowerCase().indexOf(query.toLowerCase()) === 0) {
                _filteredItems.push(item);
            }
        }

        setFilteredItems(_filteredItems);
    }

    return (
        <AutoComplete value={selectedItem} suggestions={filteredItems} completeMethod={searchItems}
            virtualScrollerOptions={{ itemSize: 38 }} field="label" dropdown onChange={(e: AutoCompleteChangeEvent) => setSelectedItem(e.value)} />
    )
}
