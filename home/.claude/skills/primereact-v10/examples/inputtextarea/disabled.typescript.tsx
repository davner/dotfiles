import React from 'react'; 
import { InputTextarea } from "primereact/inputtextarea";

export default function DisabledDemo() {
    return (
        <div className="card flex justify-content-center">
            <InputTextarea disabled rows={5} cols={30} value="Disabled" />
        </div>
    )
}
