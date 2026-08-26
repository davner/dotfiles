import React, { useRef, useState } from 'react';
import { Button } from 'primereact/button';
import { useUnmountEffect, useMountEffect } from 'primereact/hooks';

export default function BasicDemo() {
    const [hidden, setHidden] = useState<boolean>(false);
    const toast = useRef(null);

    const DynamicBox = () => {
        useUnmountEffect(() => {
            toast.current && toast.current.show({ severity: 'info', summary: 'Unmounted' });
        });

        return <div className="w-8rem h-8rem border-round bg-primary border-1 border-primary mb-3 flex justify-content-center align-items-center">Mounted</div>;
    };

    return (
        <>
            <Toast ref={toast} />
            <div className="card flex flex-column align-items-center">
                {!hidden ? <DynamicBox /> : <div className="w-8rem h-8rem border-round surface-card border-1 surface-border border-dashed mb-3 flex justify-content-center align-items-center">Unmounted</div>}
                <Button label={hidden ? 'Mount' : 'Unmount'} onClick={() => setHidden(() => !hidden)} className="p-button-outlined w-10rem" />
            </div>
        </>
    )
}
