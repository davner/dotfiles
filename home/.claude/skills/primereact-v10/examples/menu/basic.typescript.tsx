import React from 'react'; 
import { Menu } from 'primereact/menu';
import { MenuItem } from 'primereact/menuitem';

export default function BasicDemo() {
    let items: MenuItem[] = [
        { label: 'New', icon: 'pi pi-plus' },
        { label: 'Search', icon: 'pi pi-search' }
    ];

    return (
        <Menu model={items} />
    )
}
