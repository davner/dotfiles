import React, { useEffect, useRef } from 'react';
import { MeterGroup } from 'primereact/metergroup';

export default function VerticalDemo() {
    const values = [
         { label: 'Apps', color: '#34d399', value: 24 },
        { label: 'Messages', color: '#fbbf24', value: 16 },
        { label: 'Media', color: '#60a5fa', value: 24 },
        { label: 'System', color: '#c084fc', value: 12 }
    ];

    return (
        <div className="card flex justify-content-center" style={{ height: '360px' }}>
            <MeterGroup values={values} orientation="vertical" labelOrientation="vertical" />
        </div>
    )
}
