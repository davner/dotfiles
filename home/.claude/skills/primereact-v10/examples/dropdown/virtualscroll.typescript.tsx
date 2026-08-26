import React, { useState } from "react";
import { Dropdown, DropdownChangeEvent } from 'primereact/dropdown';

interface Item {
    label: string;
    value: number;
}

export default function VirtualScrollDemo() {
    const [selectedItem, setSelectedItem] = useState<Item | null>(null);
    const items: Item[] = Array.from({ length: 100000 }).map((_, i) => ({ label: `Item #${i}`, value: i }));

    return (
        <div className="card flex justify-content-center">
            <Dropdown value={selectedItem} onChange={(e: DropdownChangeEvent) => setSelectedItem(e.value)} options={items} virtualScrollerOptions={{ itemSize: 38 }} 
                placeholder="Select Item" className="w-full md:w-14rem" />
        </div>
    )
}
