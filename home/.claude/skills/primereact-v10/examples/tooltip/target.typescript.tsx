import React from 'react';
import { Tooltip } from 'primereact/tooltip';
import { Badge } from 'primereact/badge';

export default function TargetDemo() {
    return (
        <div className="card flex justify-content-center">
            <Tooltip target=".custom-target-icon" />

            <i className="custom-target-icon pi pi-envelope p-text-secondary p-overlay-badge"
                data-pr-tooltip="No notifications"
                data-pr-position="right"
                data-pr-at="right+5 top"
                data-pr-my="left center-2"
                style={{ fontSize: '2rem', cursor: 'pointer' }}>
                <Badge severity="danger"></Badge>
            </i>
        </div>
    );
}
