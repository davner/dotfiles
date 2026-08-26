import React, { useEffect, useRef } from 'react'; 
import { useMountEffect } from 'primereact/hooks';
import { Messages } from 'primereact/messages';

export default function ClosableDemo() {
    const msgs = useRef<Messages>(null);

    useMountEffect(() => {
        msgs.current?.clear();
        msgs.current?.show([
            { sticky: true, severity: 'success', summary: 'Success', detail: 'Closable Message' },
            { sticky: true, severity: 'info', summary: 'Info', detail: 'Not Closable Message', closable: false }
        ]);
    };

    return (
        <div className="card">
            <Messages ref={msgs} />
        </div>
    )
}
