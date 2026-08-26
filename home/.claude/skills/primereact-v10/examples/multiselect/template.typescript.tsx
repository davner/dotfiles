import React, { useState } from "react";
import { MultiSelect, MultiSelectChangeEvent } from 'primereact/multiselect';

interface Country {
    name: string;
    code: string;
}

export default function TemplateDemo() {
    const [selectedCountries, setSelectedCountries] = useState<Country[] | null>(null);
    const countries: Country[] = [
        { name: 'Australia', code: 'AU' },
        { name: 'Brazil', code: 'BR' },
        { name: 'China', code: 'CN' },
        { name: 'Egypt', code: 'EG' },
        { name: 'France', code: 'FR' },
        { name: 'Germany', code: 'DE' },
        { name: 'India', code: 'IN' },
        { name: 'Japan', code: 'JP' },
        { name: 'Spain', code: 'ES' },
        { name: 'United States', code: 'US' }
    ];

    const countryTemplate = (option) => {
        return (
            <div className="flex align-items-center">
                <img alt={option.name} src="https://primefaces.org/cdn/primereact/images/flag/flag_placeholder.png" className={`mr-2 flag flag-${option.code.toLowerCase()}`} style={{ width: '18px' }} />
                <div>{option.name}</div>
            </div>
        );
    };

    const panelFooterTemplate = () => {
        const length = selectedCountries ? selectedCountries.length : 0;

        return (
            <div className="py-2 px-3">
                <b>{length}</b> item{length > 1 ? 's' : ''} selected.
            </div>
        );
    };

    return (
        <div className="card flex justify-content-center">
            <MultiSelect value={selectedCountries} options={countries} onChange={(e: MultiSelectChangeEvent) => setSelectedCountries(e.value)} optionLabel="name" 
                placeholder="Select Countries" itemTemplate={countryTemplate} panelFooterTemplate={panelFooterTemplate} className="w-full md:w-20rem" display="chip" />
        </div>
    );
}
