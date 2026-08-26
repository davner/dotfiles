import React from 'react'; 
import { Button } from 'primereact/button';

export default function DelayDemo() {
    return (
        <div className="card flex justify-content-center">
            <Button tooltip="Confirm to proceed" tooltipOptions={{ showDelay: 1000, hideDelay: 300 }} label="Save" />
        </div>
    );
}
