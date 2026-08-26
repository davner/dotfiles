import React from 'react'; 
import { Button } from 'primereact/button';

export default function ExampleDemo() {
    return (
        <div className="card flex justify-content-center">
            <Button label="Submit" icon="pi pi-check" unstyled
                pt={{
                    root: { className: 'bg-teal-500 hover:bg-teal-700 cursor-pointer text-white p-3 border-round border-none flex gap-2' },
                    label: { className: 'text-white font-bold text-xl' },
                    icon: 'text-white text-2xl' // OR { className: 'text-white text-2xl' }
                }}
            />
        </div>
    )
}
