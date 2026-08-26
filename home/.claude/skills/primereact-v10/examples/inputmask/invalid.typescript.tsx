import React from 'react'; 
import { InputMask } from "primereact/inputmask";

export default function InvalidDemo() {
    return (
        <div className="card flex justify-content-center">
            <InputMask invalid mask="99-999999" placeholder="99-999999" />
        </div>
    )
}
