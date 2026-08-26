import React from 'react'; 
import { InputText } from "primereact/inputtext";

export default function KeyFilterDemo() {
    return (
        <div className="card flex justify-content-center">
            <InputText keyfilter="int" placeholder="Integers" />
        </div>
    )
}
