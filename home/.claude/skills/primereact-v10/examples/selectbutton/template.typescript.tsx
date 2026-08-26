import React, { useState } from "react";
import { SelectButton, SelectButtonChangeEvent } from 'primereact/selectbutton';

interface JustifyOption {
    icon: string;
    value: string;
}

export default function TemplateDemo() {
    const [value, setValue] = useState<JustifyOption>(null);
    const justifyOptions: JustifyOption[] = [
        {icon: 'pi pi-align-left', value: 'left'},
        {icon: 'pi pi-align-right', value: 'Right'},
        {icon: 'pi pi-align-center', value: 'Center'},
        {icon: 'pi pi-align-justify', value: 'Justify'}
    ];

    const justifyTemplate = (option: JustifyOption) => {
        return <i className={option.icon}></i>;
    }

    return (
        <div className="card flex justify-content-center">
            <SelectButton value={value} onChange={(e: SelectButtonChangeEvent) => setValue(e.value)} itemTemplate={justifyTemplate} optionLabel="value" options={justifyOptions} />
        </div>
    )
}
