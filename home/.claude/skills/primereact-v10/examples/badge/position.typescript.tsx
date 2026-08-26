import React from 'react';
import { Badge } from 'primereact/badge';

export default function PositionDemo() {
    return (
        <div className="card flex flex-wrap justify-content-center gap-4">
            <i className="pi pi-bell p-overlay-badge" style={{ fontSize: '2rem' }}>
                <Badge value="2"></Badge>
            </i>
            <i className="pi pi-calendar p-overlay-badge" style={{ fontSize: '2rem' }}>
                <Badge value="5+" severity="danger"></Badge>
            </i>
            <i className="pi pi-envelope p-overlay-badge" style={{ fontSize: '2rem' }}>
                <Badge severity="danger"></Badge>
            </i>
        </div>
    );
}
