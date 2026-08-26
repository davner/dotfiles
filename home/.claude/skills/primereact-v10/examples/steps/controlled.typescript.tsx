import React, { useState } from 'react'; 
import { Steps } from 'primereact/steps';
import { MenuItem } from 'primereact/menuitem';
import { Button } from 'primereact/button';

export default function ControlledDemo() {
    const [activeIndex, setActiveIndex] = useState(0);
    const items: MenuItem[] = [
        {
            label: 'Personal Info'
        },
        {
            label: 'Reservation'
        },
        {
            label: 'Review'
        }
    ];


    return (
        <div className="card">
            <div className="flex flex-wrap justify-content-end gap-2 mb-3">
                <Button outlined={activeIndex !== 0} rounded label="1" onClick={() => setActiveIndex(0)} className="w-2rem h-2rem p-0" />
                <Button outlined={activeIndex !== 1} rounded label="2" onClick={() => setActiveIndex(1)} className="w-2rem h-2rem p-0" />
                <Button outlined={activeIndex !== 2} rounded label="3" onClick={() => setActiveIndex(2)} className="w-2rem h-2rem p-0" />
            </div>
            <Steps model={items} activeIndex={activeIndex} />
        </div>
    )
}
