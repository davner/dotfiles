import React from 'react'; 
import { PanelMenu } from 'primereact/panelmenu';
import { MenuItem } from 'primereact/menuitem';
import { useRouter } from 'next/router';

export default function RouterDemo() {
    const router = useRouter();
    const items: MenuItem[] = [
        {
            label: 'Router',
            icon: 'pi pi-palette',
            items: [
                {
                    label: 'Styled',
                    icon: 'pi pi-eraser',
                    url: '/theming'
                },
                {
                    label: 'Unstyled',
                    icon: 'pi pi-heart',
                    url: '/unstyled'
                }
            ]
        },
        {
            label: 'Programmatic',
            icon: 'pi pi-link',
            command: () => {
                router.push('/installation');
            }
        },
        {
            label: 'External',
            icon: 'pi pi-home',
            items: [
                {
                    label: 'React.js',
                    icon: 'pi pi-star',
                    url: 'https://react.dev/'
                },
                {
                    label: 'Vite.js',
                    icon: 'pi pi-bookmark',
                    url: 'https://vite.dev/'
                }
            ]
        }
    ];

    return (
        <div className="card flex justify-content-center">
            <PanelMenu model={items} className="w-full md:w-20rem" />
        </div>
    )
}
