import React from 'react';
import { InputText } from 'primereact/inputtext';
import { useTimeout } from 'primereact/hooks';
import { Toast } from 'primereact/toast';

export default function BasicDemo() {
    const toast = useRef<Toast>(null);

    const [clearTimeout] = useTimeout(() => {
        toast.current.show({ severity: 'info', summary: 'Loaded' });
    }, 3000);

    return (
        <>
            <Toast ref={toast} />
            <div className="card flex justify-content-center">
                <span className="text-xl">A message will be displayed in 3 seconds after mount.</span>
            </div>
        </>
    )
}
