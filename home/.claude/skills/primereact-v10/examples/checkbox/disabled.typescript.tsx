import React from 'react'; 
import { Checkbox } from "primereact/checkbox";

export default function DisabledDemo() {
    return (
        <div className="card flex justify-content-center">
            <Checkbox checked disabled></Checkbox>
        </div>
    )
}
