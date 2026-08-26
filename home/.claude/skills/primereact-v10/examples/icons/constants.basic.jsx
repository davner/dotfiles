import React from 'react'; 
import { Menu } from 'primereact/menu';
import { PrimeIcons } from 'primereact/api';

export default function ConstantsDemo() {
    const items = [
        {
            label: 'File',
            items: [
                { label: 'New', icon: PrimeIcons.PLUS },
                { label: 'Open', icon: PrimeIcons.DOWNLOAD }
            ]
        }
    ];

    return (
        <Menu model={items} />
    )
}
