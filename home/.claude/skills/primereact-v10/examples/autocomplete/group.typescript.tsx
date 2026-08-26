import React, { useState } from "react";
import {
  AutoComplete,
  AutoCompleteChangeEvent,
  AutoCompleteCompleteEvent,
} from "primereact/autocomplete";

interface City {
  label: string;
  value: string;
}

interface Country {
  label: string;
  code: string;
  items: City[];
}

export default function GroupDemo() {
  const [selectedCity, setSelectedCity] = useState<Country>();
  const [filteredCities, setFilteredCities] = useState<Country[]>();
  const groupedCities: Array<Country> = [
    {
      label: "Germany",
      code: "DE",
      items: [
        { label: "Berlin", value: "Berlin" },
        { label: "Frankfurt", value: "Frankfurt" },
        { label: "Hamburg", value: "Hamburg" },
        { label: "Munich", value: "Munich" },
      ],
    },
    {
      label: "USA",
      code: "US",
      items: [
        { label: "Chicago", value: "Chicago" },
        { label: "Los Angeles", value: "Los Angeles" },
        { label: "New York", value: "New York" },
        { label: "San Francisco", value: "San Francisco" },
      ],
    },
    {
      label: "Japan",
      code: "JP",
      items: [
        { label: "Kyoto", value: "Kyoto" },
        { label: "Osaka", value: "Osaka" },
        { label: "Tokyo", value: "Tokyo" },
        { label: "Yokohama", value: "Yokohama" },
      ],
    },
  ];

  const groupedItemTemplate = (item: Country) => {
    return (
      <div className="flex align-items-center">
        <img
          alt={item.label}
          src="https://primefaces.org/cdn/primereact/images/flag/flag_placeholder.png"
          className={`flag flag-${item.code.toLowerCase()} mr-2`}
          style={{ width: "18px" }}
        />
        <div>{item.label}</div>
      </div>
    );
  };

  const search = (event: AutoCompleteCompleteEvent) => {
    let query = event.query;
    let _filteredCities = [];

    for (let country of groupedCities) {
      let filteredItems = country.items.filter(
        (item) => item.label.toLowerCase().indexOf(query.toLowerCase()) !== -1
      );

      if (filteredItems && filteredItems.length) {
        _filteredCities.push({ ...country, ...{ items: filteredItems } });
      }
    }

    setFilteredCities(_filteredCities);
  };

  return (
    <div className="card flex justify-content-center">
      <AutoComplete
        value={selectedCity}
        onChange={(e: AutoCompleteChangeEvent) => setSelectedCity(e.value)}
        suggestions={filteredCities}
        completeMethod={search}
        field="label"
        optionGroupLabel="label"
        optionGroupChildren="items"
        optionGroupTemplate={groupedItemTemplate}
        placeholder="Hint: type 'a'"
      />
    </div>
  );
}
