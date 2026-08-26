import React from 'react';
import { InputText } from 'primereact/inputtext';

export default function AutoHideDemo() {

    return (
        <div className="card flex flex-wrap align-items-center justify-content-center gap-2">
            <InputText type="text" placeholder="autoHide: false" tooltip="Enter your username" tooltipOptions={{ autoHide: false }} />
            <InputText type="text" placeholder="autoHide: true" tooltip="Enter your username" />
        </div>
    );
}
