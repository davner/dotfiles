import React from "react";
import { CascadeSelect } from 'primereact/cascadeselect';

export default function DisabledDemo() {
    return (
        <div className="card flex justify-content-center">
            <CascadeSelect disabled placeholder="Disabled" style={{ minWidth: '14rem' }} />
        </div>
    )
}
