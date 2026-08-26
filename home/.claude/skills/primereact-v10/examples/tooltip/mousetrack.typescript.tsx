import React from 'react'; 
import { Tooltip } from 'primereact/tooltip';
import { Button } from 'primereact/button';

export default function MouseTrackDemo() {
    return (
        <div className="card flex flex-wrap align-items-center justify-content-center gap-5">
            <Button type="button" label="Save" icon="pi pi-check" tooltip="Save" tooltipOptions={{ position: 'bottom', mouseTrack: true, mouseTrackTop: 15 }} />

            <Tooltip target=".logo" mouseTrack mouseTrackLeft={10} />
            <img className="logo" alt="logo" src="https://primefaces.org/cdn/primereact/images/logo.png" data-pr-tooltip="PrimeReact-Logo" height="80px" />
        </div>
    );
}
