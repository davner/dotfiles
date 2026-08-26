import React, { useRef } from 'react';
import { Toast } from 'primereact/toast';
import { Button } from 'primereact/button';

export default function MultipleDemo() {
    const toast = useRef<Toast>(null);

    const showMultiple = () => {
        toast.current?.show([
            { severity: 'success', summary: 'Success', detail: 'Message Content', life: 3000 },
            { severity: 'info', summary: 'Info', detail: 'Message Content', life: 3050 },
            { severity: 'warn', summary: 'Warning', detail: 'Message Content', life: 3100 },
            { severity: 'error', summary: 'Error', detail: 'Message Content', life: 3150 }
        ]);
    };

    return (
        <div className="card flex justify-content-center gap-2">
            <Toast ref={toast} />
            <Button onClick={showMultiple} label="Multiple" severity='warning' />
        </div>
    )
}
