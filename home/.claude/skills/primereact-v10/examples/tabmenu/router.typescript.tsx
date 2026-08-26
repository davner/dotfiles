import React from 'react'; 
import { TabMenu } from 'primereact/tabmenu';
import { MenuItem } from 'primereact/menuitem';
import { useRouter } from 'next/router';

export default function RouterDemo() {
    const router = useRouter();
    const items: MenuItem[] = [
        { label: 'Router Link', icon: 'pi pi-home', url: '/tabmenu' },
        {
            label: 'Programmatic',
            icon: 'pi pi-palette',
            command: () => {
                router.push('/unstyled');
            }
        },
        { label: 'External', icon: 'pi pi-link', url: 'https://react.dev/' }
    ];

    return (
        <div className="card">
            <TabMenu model={items} />
        </div>
    )
}
