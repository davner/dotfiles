import React from 'react'; 
import { Button } from 'primereact/button';
import { ButtonGroup } from 'primereact/buttongroup';

export default function ButtonSetDemo() {
    return (
        <div className="card flex justify-content-center">
            <ButtonGroup>
                <Button label="Save" icon="pi pi-check" />
                <Button label="Delete" icon="pi pi-trash" />
                <Button label="Cancel" icon="pi pi-times" />
            </ButtonGroup>
        </div>
    )
}
