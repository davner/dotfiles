import React from "react";
import { ListBox } from 'primereact/listbox';

interface City {
    name: string;
    code: string;
}

export default function DisabledDemo() {
    const cities: City[] = [
        { name: 'New York', code: 'NY' },
        { name: 'Rome', code: 'RM' },
        { name: 'London', code: 'LDN' },
        { name: 'Istanbul', code: 'IST' },
        { name: 'Paris', code: 'PRS' }
    ];

    return (
        <div className="card flex justify-content-center">
            <ListBox disabled options={cities} optionLabel="name" className="w-full md:w-14rem" />
        </div>
    )
}
