import React, { useState } from 'react';
import { InputText } from 'primereact/inputtext';
import { usePrevious } from 'primereact/hooks';

export default function BasicDemo() {
    const [value, setValue] = useState<string>('');
    const prevValue = usePrevious(value);

    return (
        <div className="card flex flex-column align-items-center">
            <InputText value={value} className="mb-4" 
                onChange={(e: React.ChangeEvent<HTMLInputElement>) => setValue(e.target.value)} />
            <div className="flex flex-column align-items-start flex-wrap gap-3 text-xl">
                <span>
                    Current: <strong>{value}</strong>
                </span>
                <span>
                    Previous: <strong>{prevValue}</strong>
                </span>
            </div>
        </div>
    )
}
