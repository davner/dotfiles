import React from 'react';
import { Tag } from 'primereact/tag';

export default function SeverityDemo() {
    return (
        <div className="card flex flex-wrap justify-content-center gap-2">
            <Tag value="Primary"></Tag>
            <Tag severity="success" value="Success"></Tag>
            <Tag severity="info" value="Info"></Tag>
            <Tag severity="warning" value="Warning"></Tag>
            <Tag severity="danger" value="Danger"></Tag>
            <Tag severity="secondary" value="Secondary"></Tag>
            <Tag severity="contrast" value="Contrast"></Tag>
        </div>
    );
}
