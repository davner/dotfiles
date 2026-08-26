import React from 'react'; 
import { InputMask } from "primereact/inputmask";

export default function DisabledDemo() {
    return (
        <div className="card flex justify-content-center">
            <InputMask mask="99-999999" placeholder="99-999999" disabled />
        </div>
    )
}
