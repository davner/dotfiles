import React from 'react'; 
import { Chips } from "primereact/chips";

export default function DisabledDemo() {
    return (
        <div className="card p-fluid">
            <Chips disabled placeholder="Disabled" />
        </div>
    )
}
