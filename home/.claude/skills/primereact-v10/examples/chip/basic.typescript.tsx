import React from 'react';
import { Chip } from 'primereact/chip';

export default function BasicDemo() {
    return (
        <div className="card flex flex-wrap gap-2">
            <Chip label="Action" />
            <Chip label="Comedy" />
            <Chip label="Mystery" />
            <Chip label="Thriller" removable />
        </div>
    );
}
