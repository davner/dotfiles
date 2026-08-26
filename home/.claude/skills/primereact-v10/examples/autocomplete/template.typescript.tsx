import React, { useEffect, useState } from 'react';
import { AutoComplete, AutoCompleteCompleteEvent } from "primereact/autocomplete";
import { CountryService } from './service/CountryService';

interface Country {
    name: string;
    code: string;
}

export default function TemplateDemo() {
    const [countries, setCountries] = useState<Country[]>([]);
    const [selectedCountry, setSelectedCountry] = useState<Country>(null);
    const [filteredCountries, setFilteredCountries] = useState<Country[]>(null);
    
    const search = (event: AutoCompleteCompleteEvent) => {
        // Timeout to emulate a network connection
        setTimeout(() => {
            let _filteredCountries;

            if (!event.query.trim().length) {
                _filteredCountries = [...countries];
            }
            else {
                _filteredCountries = countries.filter((country) => {
                    return country.name.toLowerCase().startsWith(event.query.toLowerCase());
                });
            }

            setFilteredCountries(_filteredCountries);
        }, 250);
    }

    const itemTemplate = (item: Country) => {
        return (
            <div className="flex align-items-center">
                <img
                    alt={item.name}
                    src="https://primefaces.org/cdn/primereact/images/flag/flag_placeholder.png"
                    className={`flag flag-${item.code.toLowerCase()} mr-2`}
                    style={{width: '18px'}}
                />
                <div>{item.name}</div>
            </div>
        );
    };

    const selectedItemTemplate = (item: Country) => {
        return item.name + ' (' + item.code.toUpperCase() + ')';
    };
    
    const panelFooterTemplate = () => {
        const isCountrySelected = (filteredCountries || []).some( country => country['name'] === selectedCountry );
           return (
            <div className="py-2 px-3">
                {isCountrySelected ? (
                    <span>
                        <b>{selectedCountry}</b> selected.
                    </span>
                ) : (
                    'No country selected.'
                )}
            </div>
        );
    };

    useEffect(() => {
        CountryService.getCountries().then((data) => setCountries(data));
    }, []);

    return (
        <div className="card flex justify-content-center">
            <AutoComplete field="name" value={selectedCountry} suggestions={filteredCountries} 
                completeMethod={search} onChange={(e: AutoCompleteChangeEvent) => setSelectedCountry(e.value)} itemTemplate={itemTemplate} panelFooterTemplate={panelFooterTemplate} selectedItemTemplate={selectedItemTemplate} />
        </div>
    )
}
