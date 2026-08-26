import React, { useState } from "react";
import { InputNumber, InputNumberValueChangeEvent } from 'primereact/inputnumber';

export default function CurrencyDemo() {
    const [value1, setValue1] = useState<number>(1500);
    const [value2, setValue2] = useState<number>(2500);
    const [value3, setValue3] = useState<number>(4250);
    const [value4, setValue4] = useState<number>(5002);

    return (
        <div className="card flex flex-wrap gap-3 p-fluid">
            <div className="flex-auto">
                <label htmlFor="currency-us" className="font-bold block mb-2">United States</label>
                <InputNumber inputId="currency-us" value={value1} onValueChange={(e: InputNumberValueChangeEvent) => setValue1(e.value)} mode="currency" currency="USD" locale="en-US" />
            </div>
            <div className="flex-auto">
                <label htmlFor="currency-germany" className="font-bold block mb-2">Germany</label>
                <InputNumber inputId="currency-germany" value={value2} onValueChange={(e: InputNumberValueChangeEvent) => setValue2(e.value)} mode="currency" currency="EUR" locale="de-DE" />
            </div>
            <div className="flex-auto">
                <label htmlFor="currency-india" className="font-bold block mb-2">India</label>
                <InputNumber inputId="currency-india" value={value3} onValueChange={(e: InputNumberValueChangeEvent) => setValue3(e.value)} mode="currency" currency="INR" currencyDisplay="code" locale="en-IN" />
            </div>
            <div className="flex-auto">
                <label htmlFor="currency-japan" className="font-bold block mb-2">Japan</label>
                <InputNumber inputId="currency-japan" value={value4} onValueChange={(e: InputNumberValueChangeEvent) => setValue4(e.value)} mode="currency" currency="JPY" locale="jp-JP" />
            </div>
        </div>
    )
}
