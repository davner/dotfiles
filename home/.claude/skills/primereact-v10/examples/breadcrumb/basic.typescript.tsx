import React from 'react';
import { BreadCrumb } from 'primereact/breadcrumb';
import { MenuItem } from 'primereact/menuitem';

export default function BasicDemo() {
    const items: MenuItem[] = [{ label: 'Electronics' }, { label: 'Computer' }, { label: 'Accessories' }, { label: 'Keyboard' }, { label: 'Wireless' }];
    const home: MenuItem = { icon: 'pi pi-home', url: 'https://primereact.org' }

    return (
        <BreadCrumb model={items} home={home} />
    )
}
