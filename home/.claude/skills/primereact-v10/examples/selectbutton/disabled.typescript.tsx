import React, { useState } from "react";
import { SelectButton, SelectButtonChangeEvent } from 'primereact/selectbutton';

interface Item {
    name: string;
    value: number;
    constant: boolean;
}

export default function DisabledDemo() {
    const [value, setValue] = useState(null);
    const options1: string[] = ['Off', 'On'];
    const options2: Item[] = [
        { name: 'Option 1', value: 1 },
        { name: 'Option 2', value: 2, constant: true }
    ];
    
    return (
        <div className="card flex flex-wrap justify-content-center flex-wrap gap-3">
            <SelectButton disabled options={options1} />
            <SelectButton value={value} onChange={(e: SelectButtonChangeEvent) => setValue(e.value)} options={options2} optionLabel="name" optionDisabled="constant" />
        </div>
    );
}
