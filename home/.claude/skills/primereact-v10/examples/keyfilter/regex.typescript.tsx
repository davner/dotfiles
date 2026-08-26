import React from 'react'; 
import { InputText } from 'primereact/inputtext';

export default function RegexDemo() {
    return (
        <div className="card flex flex-wrap gap-3">
            <div className="flex-auto">
                <label htmlFor="spacekey" className="font-bold block mb-2">
                    Block Space
                </label>
                <InputText id="spacekey" keyfilter={/[^\s]/} className="w-full" />
            </div>
            <div className="flex-auto">
                <label htmlFor="chars" className="font-bold block mb-2">
                    Block {`< > * !`}
                </label>
                <InputText id="chars" keyfilter={/^[^<>*!]+$/} className="w-full" />
            </div>
        </div>
    )
}
