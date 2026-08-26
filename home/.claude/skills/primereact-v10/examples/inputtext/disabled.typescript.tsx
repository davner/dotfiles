import React from 'react'; 
import { InputText } from "primereact/inputtext";

export default function DisabledDemo() {
    return (
        <div className="card flex justify-content-center">
            <InputText disabled placeholder="Disabled" />
        </div>
    )
}
