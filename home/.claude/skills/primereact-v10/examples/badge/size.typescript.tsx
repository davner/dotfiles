import React from 'react';
import { Badge } from 'primereact/badge';

export default function SizeDemo() {
    return (
        <div className="card flex flex-wrap justify-content-center align-items-end gap-2">
            <Badge value="6" size="xlarge" severity="success"></Badge>
            <Badge value="4" size="large" severity="warning"></Badge>
            <Badge value="2"></Badge>
        </div>
    );
}
