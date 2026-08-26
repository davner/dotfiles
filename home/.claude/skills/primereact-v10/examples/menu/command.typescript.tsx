import React, { useRef } from 'react'; 
import { Menu } from 'primereact/menu';
import { MenuItem } from 'primereact/menuitem';
import { Toast } from 'primereact/toast';


export default function CommandDemo() {
    const toast = useRef<Toast>(null);
    let items: MenuItem[] = [
        {
            label: 'New',
            icon: 'pi pi-plus',
            command: () => {
                toast.current.show({ severity: 'success', summary: 'Success', detail: 'File created', life: 3000 });
            }
        },
        {
            label: 'Search',
            icon: 'pi pi-search',
            command: () => {
                toast.current.show({ severity: 'warn', summary: 'Search Completed', detail: 'No results found', life: 3000 });
            }
        }
    ];

    return (
        <Menu model={items} />
        <Toast ref={toast} />
    )
}
