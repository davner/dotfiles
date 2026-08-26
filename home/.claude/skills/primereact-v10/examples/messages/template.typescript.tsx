import React, { useEffect, useRef } from 'react'; 
import { useMountEffect } from 'primereact/hooks';
import { Messages } from 'primereact/messages';

export default function TemplateDemo() {
    const msgs = useRef<Messages>(null);

    useMountEffect(() => {
        msgs.current>.clear();
        msgs.current?.show({
            severity: 'info', sticky: true, content: (
                <React.Fragment>
                    <img alt="logo" src="https://primefaces.org/cdn/primereact/images/logo.png" width="32" />
                    <div className="ml-2">Always bet on Prime.</div>
                </React.Fragment>
            )
        });
    });

    return (
        <div className="card">
            <Messages ref={msgs} />
        </div>
    )
}
