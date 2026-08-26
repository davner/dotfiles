import React from 'react';
import { Tag } from 'primereact/tag';

export default function PillDemo() {
    return (
        <div className="card flex flex-wrap justify-content-center gap-2">
            <Tag value="Primary" rounded></Tag>
            <Tag severity="success" value="Success" rounded></Tag>
            <Tag severity="info" value="Info" rounded></Tag>
            <Tag severity="warning" value="Warning" rounded></Tag>
            <Tag severity="danger" value="Danger" rounded></Tag>
            <Tag severity="secondary" value="Secondary" rounded></Tag>
            <Tag severity="contrast" value="Contrast" rounded></Tag>
        </div>
    );
}
