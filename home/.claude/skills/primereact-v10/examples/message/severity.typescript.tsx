import React from 'react'; 
import { Message } from 'primereact/message';

export default function SeverityDemo() {
    return (
        <div className="card flex flex-wrap align-items-center justify-content-center gap-3">
            <Message severity="success" text="Success Message" />
            <Message severity="info" text="Info Message" />
            <Message severity="warn" text="Warning Message" />
            <Message severity="error" text="Error Message" />
            <Message severity="secondary" text="Secondary Message" />
            <Message severity="contrast" text="Contrast Message" />
        </div>
    )
}
