import { useState } from 'react';
import { TabMenu } from 'primereact/tabmenu';

export default function TemplateDemo() {
    const [activeIndex, setActiveIndex] = useState<number>(0);
    const itemRenderer = (item, itemIndex) => (
        <a className="p-menuitem-link flex align-items-center gap-2" onClick={() => setActiveIndex(itemIndex)}>
            <img alt={item.name} src={`https://primefaces.org/cdn/primereact/images/avatar/${item.image}`} style={{ width: '32px' }} />
            <span className="font-bold">{item.name}</span>
        </a>
    );

    const items = [
        {
            name: 'Amy Elsner',
            image: 'amyelsner.png',
            template: (item) => itemRenderer(item, 0)
        },
        {
            name: 'Anna Fali',
            image: 'annafali.png',
            template: (item) => itemRenderer(item, 1)
        },
        {
            name: 'Asiya Javayant',
            image: 'asiyajavayant.png',
            template: (item) => itemRenderer(item, 2)
        }
    ];

    return (
        <div className="card">
            <TabMenu model={items} activeIndex={activeIndex} onTabChange={(e) => setActiveIndex(e.index)} />
        </div>
    )
}
