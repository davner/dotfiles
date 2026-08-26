import React, { useRef } from 'react';
import { Button } from 'primereact/button';
import { Toast } from 'primereact/toast';

export default function SeverityDemo() {
    const toast = useRef<Toast>(null);

    const showSuccess = () => {
        toast.current?.show({severity:'success', summary: 'Success', detail:'Message Content', life: 3000});
    }

    const showInfo = () => {
        toast.current?.show({severity:'info', summary: 'Info', detail:'Message Content', life: 3000});
    }

    const showWarn = () => {
        toast.current?.show({severity:'warn', summary: 'Warning', detail:'Message Content', life: 3000});
    }

    const showError = () => {
        toast.current?.show({severity:'error', summary: 'Error', detail:'Message Content', life: 3000});
    }

    const showSecondary = () => {
        toast.current?.show({ severity: 'secondary', summary: 'Secondary', detail: 'Message Content', life: 3000 });
    };

    const showContrast = () => {
        toast.current?.show({ severity: 'contrast', summary: 'Contrast', detail: 'Message Content', life: 3000 });
    };


    return (
        <div className="card flex justify-content-center">
            <Toast ref={toast} />
            <div className="flex flex-wrap gap-2">
                <Button label="Success" severity="success" onClick={showSuccess} />
                <Button label="Info" severity="info" onClick={showInfo} />
                <Button label="Warn" severity="warning" onClick={showWarn} />
                <Button label="Error" severity="danger" onClick={showError} />
                <Button label="Secondary" severity="secondary" onClick={showSecondary} />
                <Button label="Contrast" severity="contrast" onClick={showContrast} />
            </div>
        </div>
    )
}
