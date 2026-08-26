import React, { useState } from "react";
import { Slider, SliderChangeEvent } from "primereact/slider";
import { SelectButton } from "primereact/selectbutton";

export default function FilterDemo() {
    const [value, setValue] = useState<number>(null);

    return (
        <div className="card flex justify-content-center">
            <div className="flex flex-column align-items-center">
                <img alt="user header" className="w-full md:w-20rem border-round mb-4" src="https://primefaces.org/cdn/primevue/images/card-vue.jpg" style={filterStyle()} />
                <SelectButton value={filter} onChange={(e) => setFilter(e.value)} options={filterOptions} className="mb-3" />
                <Slider
                    value={filterValues[filter]}
                    onChange={(e) => {
                        const newFilterValues = [...filterValues];
                        newFilterValues[filter] = e.value;
                        setFilterValues(newFilterValues);
                    }}
                    className="w-14rem"
                    min={0}
                    max={200}
                />
            </div>
        </div>
    )
}
