import React, { useState } from "react";
import { MultiSelect, MultiSelectChangeEvent, MultiSelectAllEvent } from 'primereact/multiselect';

export default function VirtualScrollDemo() {
    const [selectAll, setSelectAll] = useState(false);
    const [selectedItems, setSelectedItems] = useState(null);
    const [items] = useState(Array.from({ length: 100000 }).map((_, i) => ({ label: `Item #${i}`, value: i })));

    return (
        <div className="card flex justify-content-center">
            <MultiSelect
            value={selectedItems}
            options={items}
            onChange={(e: MultiSelectChangeEvent) => {
                setSelectedItems(e.value);
                setSelectAll(e.value.length === items.length);
            }}
            selectAll={selectAll}
            onSelectAll={(e: MultiSelectAllEvent) => {
                setSelectedItems(e.checked ? [] : items.map((item) => item.value));
                setSelectAll(!e.checked);
            }}
            virtualScrollerOptions={{ itemSize: 43 }}
            maxSelectedLabels={3}
            placeholder="Select Items"
            className="w-full md:w-20rem"
        />
        </div>
    );
}
