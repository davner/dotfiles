import React from "react";
import { IconField } from "primereact/iconfield";
import { InputIcon } from "primereact/inputicon";
import { InputText } from "primereact/inputtext";

export default function BasicDemo() {
    return (
        <div className="flex gap-3">
            <IconField iconPosition="left">
                <InputIcon className="pi pi-search"> </InputIcon>
                <InputText placeholder="Search" />
            </IconField>

            <IconField>
                <InputIcon className="pi pi-spin pi-spinner"> </InputIcon>
                <InputText />
            </IconField>
        </div>
    )
}
