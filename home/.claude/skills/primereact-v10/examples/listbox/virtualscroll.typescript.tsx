import React, { useState } from "react";
import { ListBox, ListBoxChangeEvent } from 'primereact/listbox';

interface Item {
    label: string;
    value: number;
}

export default function VirtualScrollDemo() {
    const [selectedItem, setSelectedItem] = useState<Item | null>(null);
    const items: Item[] = Array.from({ length: 100000 }).map((_, i) => ({ label: `Item #${i}`, value: i }));

    return (
        <div className="card flex justify-content-center">
            <ListBox value={selectedItem} onChange={(e: ListBoxChangeEvent) => setSelectedItem(e.value)} options={items} 
                virtualScrollerOptions={{ itemSize: 38 }} className="w-full md:w-14rem" listStyle={{ height: '250px' }} />
        </div>
    )
}
