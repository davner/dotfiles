import React from 'react'; 
import { InputText } from "primereact/inputtext";

export default function SizesDemo() {
    return (
        <div className="card flex flex-column align-items-center gap-3 ">
            <InputText type="text" className="p-inputtext-sm" placeholder="Small" />
            <InputText type="text" placeholder="Normal" />
            <InputText type="text" className="p-inputtext-lg" placeholder="Large" />
        </div>
    )
}
