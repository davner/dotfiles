import React from 'react'; 
import { Button } from 'primereact/button';

export default function SizesDemo() {
    return (
        <div className="card flex flex-wrap align-items-center justify-content-center gap-3">
            <Button label="Small" icon="pi pi-check" size="small" />
            <Button label="Normal" icon="pi pi-check" />
            <Button label="Large" icon="pi pi-check" size="large" />
        </div>
    )
}
