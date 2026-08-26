import React from 'react';
import { Knob } from 'primereact/knob';

export default function DisabledDoc() {
    return (
        <div className="card flex justify-content-center">
            <Knob value={50} disabled />
        </div>
    )
}
