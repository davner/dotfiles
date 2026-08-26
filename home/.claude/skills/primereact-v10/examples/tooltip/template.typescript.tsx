import React from 'react'; 
import { Tooltip } from 'primereact/tooltip';
import { Button } from 'primereact/button';

export default function TemplateDemo() {
    return (
        <div className="card flex justify-content-center">
            <Tooltip target=".custom-tooltip-btn">
                <img alt="logo" src="https://primefaces.org/cdn/primereact/images/logo.png" data-pr-tooltip="PrimeReact-Logo" height="80px" />
            </Tooltip>

            <Button className="custom-tooltip-btn" type="button" label="Save" icon="pi pi-check" />
        </div>
    );
}
