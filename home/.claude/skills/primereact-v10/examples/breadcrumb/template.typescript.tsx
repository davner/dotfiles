import React from 'react';
import { BreadCrumb } from 'primereact/breadcrumb';
import { MenuItem, MenuItemOptions } from 'primereact/menuitem';

export default function TemplateDoc() {
    const iconItemTemplate = (item: MenuItem, options: MenuItemOptions) => {
        return (
            <a className={options.className}>
                <span className={item.icon}></span>
            </a>
        );
    };

    const items: MenuItem[]  = [
        { icon: 'pi pi-sitemap', template: iconItemTemplate },
        { icon: 'pi pi-book', template: iconItemTemplate },
        { icon: 'pi pi-wallet', template: iconItemTemplate },
        { icon: 'pi pi-shopping-bag', template: iconItemTemplate },
        { icon: 'pi pi-calculator', template: iconItemTemplate }
    ];

    const home: MenuItem = { icon: 'pi pi-home', url: 'https://www.primereact.org' };

    return (
        <BreadCrumb model={items} home={home} />
    )
}
