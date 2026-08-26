import React, { useState } from "react";
import { SelectButton, SelectButtonChangeEvent } from 'primereact/selectbutton';

interface Item {
    name: string;
    value: number;
}

export default function MultipleDemo() {
    const [value, setValue] = useState<Item>(null);
    const items: Item[] = [
        {name: 'Option 1', value: 1},
        {name: 'Option 2', value: 2},
        {name: 'Option 3', value: 3}
    ];
    
    return (
        <div className="card flex justify-content-center">
            <SelectButton value={value} onChange={(e: SelectButtonChangeEvent) => setValue(e.value)} optionLabel="name" options={items} multiple />
        </div>
    );
}
