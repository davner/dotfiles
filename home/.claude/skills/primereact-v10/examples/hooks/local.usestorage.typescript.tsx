import React from 'react';
import { Button } from 'primereact/button';
import { useLocalStorage } from 'primereact/hooks';

export default function LocalDemo() {
    const [count, setCount] = useLocalStorage(0, 'count');
    
    return (
        <div className="card flex flex-column align-items-center">
            <span className="font-bold text-4xl mb-5">{count}</span>
            <div className="flex flex-wrap gap-3">
                <Button icon="pi pi-plus" className="p-button-outlined p-button-rounded p-button-success" onClick={() => setCount(count + 1)}></Button>
                <Button icon="pi pi-times" className="p-button-outlined p-button-rounded p-button-danger" onClick={() => setCount(0)}></Button>
            </div>
        </div>
    )
}
