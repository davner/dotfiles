import React from 'react'; 
import { Steps } from 'primereact/steps';
import { MenuItem } from 'primereact/menuitem';

export default function LinearDemo() {
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
            <Steps readOnly model={items} />
        </div>
    )
}
