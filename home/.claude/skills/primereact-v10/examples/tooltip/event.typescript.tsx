import React from 'react'; 
import { InputText } from 'primereact/inputtext';

export default function EventDemo() {
    return (
        <div className="card flex justify-content-center gap-2">
            <InputText type="text" placeholder="Hover" tooltip="Enter your username"/>
            <InputText type="text" placeholder="Focus" tooltip="Enter your username" tooltipOptions={{ event: 'focus' }} />
            <InputText type="text" placeholder="Both" tooltip="Enter your username" tooltipOptions={{ event: 'both' }} />
        </div>
    );
}
