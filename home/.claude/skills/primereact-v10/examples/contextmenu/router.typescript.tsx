import { ContextMenu } from 'primereact/contextmenu';
import { useRef, MouseEvent } from 'react';
import { useRouter } from 'next/router'
import { MenuItem } from 'primereact/menuitem';

export function RouterDemo(props: any) {
    const cm = useRef<ContextMenuRef | null>(null);
    const router = useRouter();
    const items: MenuItem[] = [
        {
            label: 'Router Link',
            icon: 'pi pi-palette',
            url: '/unstyled'
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
            url: 'https://react.dev/'
        }
    ];

    const onRightClick = (event: MouseEvent) => {
        cm.current?.show(event);
    };

    return (
        <div className="card flex md:justify-content-center">
            <span className="inline-flex align-items-center justify-content-center border-2 border-primary border-round w-4rem h-4rem" onContextMenu={(event) => onRightClick(event)} aria-haspopup="true">
                <img alt="logo" src="https://primefaces.org/cdn/primereact/images/logo.png" height="40"></img>
            </span>
            <ContextMenu model={items} ref={cm} />
        </div>
    )
}