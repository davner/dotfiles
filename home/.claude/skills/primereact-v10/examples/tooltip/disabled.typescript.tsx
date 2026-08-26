import React from 'react'; 
import { Tooltip } from 'primereact/tooltip';
import { Button } from 'primereact/button';

export default function DisabledDemo() {
    return (
        <div className="card flex flex-wrap justify-content-center gap-2">
            <Tooltip target=".disabled-button" />
            <span className="disabled-button" data-pr-tooltip="Disabled">
                <Button type="button" label="Save" icon="pi pi-check" disabled />
            </span>

            <Button type="button" label="Save" icon="pi pi-check" disabled tooltip="Disabled" tooltipOptions={{ showOnDisabled: true }} />
        </div>
    );
}
