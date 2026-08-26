import React, { useState } from 'react';
import { InputText } from 'primereact/inputtext';
import { Toast } from 'primereact/toast';
import { useUpdateEffect } from 'primereact/hooks';

export default function BasicDemo() {
    const toast = useRef(null);
    const [value, setValue] = useState<string>('');

    useUpdateEffect(() => {
        toast.current.show({ severity: 'info', summary: 'Updated' });
    }, [value]);

    return (
        <>
            <Toast ref={toast} />
            <div className="card flex justify-content-center">
                <InputText type="text" defaultValue={value} onBlur={(e: React.ChangeEvent<HTMLInputElement>) => setValue(e.target.value)} />
            </div>
        </>
    )
}
