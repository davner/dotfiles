import React from 'react';
import { BreadCrumb } from 'primereact/breadcrumb';
import { MenuItem } from 'primereact/menuitem';
import Link from 'next/link';

export default function RouterDemo() {
    const items: MenuItem[] = [
        { label: 'Components' },
        { label: 'Form' },
        {
            label: 'InputText',
            template: () => <Link href="/inputtext"><a className="text-primary font-semibold">InputText</a></Link>
        }
    ];
    const home: MenuItem = { icon: 'pi pi-home', url: 'https://primereact.org' };

    return (
        <BreadCrumb model={items} home={home} />
    )
}