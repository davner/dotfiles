import React from 'react'; 
import { RadioButton } from "primereact/radiobutton";

export default function DisabledDemo() {
    return (
        <div className="card flex justify-content-center">
            <RadioButton checked disabled></RadioButton>
        </div>
    )
}
