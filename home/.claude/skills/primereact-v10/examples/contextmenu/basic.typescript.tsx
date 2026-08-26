import React, { useRef } from 'react';
import { ContextMenu } from 'primereact/contextmenu';
import { MenuItem } from 'primereact/menuitem';

export default function BasicDemo() {
    const cm = useRef<ContextMenu>(null);
    const items: MenuItem[] = [
        { label: 'Copy', icon: 'pi pi-copy' },
        { label: 'Rename', icon: 'pi pi-file-edit' }
    ];

    return (
        <div className="card flex md:justify-content-center">
            <ContextMenu model={items} ref={cm} breakpoint="767px" />
            <img src="https://primefaces.org/cdn/primereact/images/nature/nature3.jpg" alt="Logo" className="max-w-full" onContextMenu={(e) => cm.current?.show(e)} />
        </div>
    )
}
