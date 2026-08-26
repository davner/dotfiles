import React from 'react'; 
import { InputText } from "primereact/inputtext";

export default function InvalidDemo() {
    return (
        <div className="card flex justify-content-center">
            <InputText invalid />
        </div>
    )
}
