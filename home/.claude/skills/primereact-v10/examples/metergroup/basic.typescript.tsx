import React, { useEffect, useRef } from 'react';
import { MeterGroup } from 'primereact/metergroup';

export default function BasicDemo() {
    const values = [{ label: 'Space used', value: 15 }];

    return (
        <div className="card flex justify-content-center">
            <MeterGroup values={values} />
        </div>
    )
}
