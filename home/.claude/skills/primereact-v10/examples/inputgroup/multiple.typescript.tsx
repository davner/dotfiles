import React from 'react'; 
import { InputNumber } from 'primereact/inputnumber';

export default function MultipleDemo() {
    return (
        <div className="card flex justify-content-center">
            <div className="p-inputgroup w-full md:w-30rem">
                <span className="p-inputgroup-addon">
                    <i className="pi pi-clock"></i>
                </span>
                <span className="p-inputgroup-addon">
                    <i className="pi pi-star-fill"></i>
                </span>
                <InputNumber placeholder="Price" />
                <span className="p-inputgroup-addon">$</span>
                <span className="p-inputgroup-addon">.00</span>
            </div>
        </div>
    )
}
