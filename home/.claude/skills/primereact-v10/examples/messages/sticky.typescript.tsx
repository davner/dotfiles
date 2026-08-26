import React, { useEffect, useRef } from 'react'; 
import { useMountEffect } from 'primereact/hooks';
import { Messages } from 'primereact/messages';

export default function StickyDemo() {
    const msgs = useRef<Messages>(null);

    useMountEffect(() => {
        msgs.current?.clear();
        msgs.current?.show([
            { sticky: true, life: 1000, severity: 'success', summary: 'Success', detail: 'Message Content', closable: false },
            { sticky: true, life: 2000, severity: 'info', summary: 'Info', detail: 'Message Content', closable: false },
            { sticky: true, life: 3000, severity: 'warn', summary: 'Warning', detail: 'Message Content', closable: false },
            { sticky: true, life: 4000, severity: 'error', summary: 'Error', detail: 'Message Content', closable: false }
        ]);
    });

    return (
        <div className="card">
            <Messages ref={msgs} />
        </div>
    )
}
