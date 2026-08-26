import React, { useState } from "react";
import { MultiSelect, MultiSelectChangeEvent } from 'primereact/multiselect';
import { FloatLabel } from 'primereact/floatlabel';

interface City {
    name: string;
    code: string;
}

export default function FloatLabelDemo() {
    const [selectedCities, setSelectedCities] = useState<City | null>(null);
    const cities: City[] = [
        { name: 'New York', code: 'NY' },
        { name: 'Rome', code: 'RM' },
        { name: 'London', code: 'LDN' },
        { name: 'Istanbul', code: 'IST' },
        { name: 'Paris', code: 'PRS' }
    ];

    return (
        <div className="card flex justify-content-center">
            <FloatLabel className="w-full md:w-20rem">
                <MultiSelect value={selectedCities} onChange={(e) => setSelectedCities(e.value)} options={cities} optionLabel="name" maxSelectedLabels={3} className="w-full" />
                <label htmlFor="ms-cities">MultiSelect</label>
            </FloatLabel>
        </div>
    );
}
