import React from 'react'; 
import { useMountEffect } from 'primereact/hooks';
import { Toast } from 'primereact/toast';

export default function BasicDemo() {
    const toast = useRef<Toast>(null);

    useMountEffect(() => {
        toast.current.show({ severity: 'info', summary: 'Mounted', sticky: true });
    });

    return (
        <>
            <Toast ref={toast} />
            <div className="card flex justify-content-center">
                <span className="text-xl">View the Toast message at top right.</span>
            </div>
        </>
    )
}
