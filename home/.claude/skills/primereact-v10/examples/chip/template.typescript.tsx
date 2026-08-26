import React from 'react';
import { Chip } from 'primereact/chip';

export default function TemplateDemo() {
    const content = (
        <>
            <span className="bg-primary border-circle w-2rem h-2rem flex align-items-center justify-content-center">P</span>
            <span className="ml-2 font-medium">PRIME</span>
        </>
    );

    return (
        <div className="card">
            <Chip className="pl-0 pr-3" template={content} />
        </div>
    );
}
