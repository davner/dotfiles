import React, { useState } from 'react';
import { VirtualScroller, VirtualScrollerTemplateOptions } from 'primereact/virtualscroller';
import { classNames } from 'primereact/utils';

export default function DelayDemo() {
    const [items] = useState<string[]>(Array.from({ length: 100000 }).map((_, i) => `Item #${i}`));

    const itemTemplate = (item: string, options: VirtualScrollerTemplateOptions) => {
        const className = classNames('flex align-items-center p-2', {
            'surface-hover': options.odd
        });

        return (
            <div className={className} style={{ height: options.props.itemSize + 'px' }}>
                {item}
            </div>
        );
    };

    return ( 
        <div className="card flex flex-wrap justify-content-center gap-5">
            <div>
                <span className="font-bold block mb-2">No Delay</span>
                <VirtualScroller items={items} itemSize={50} itemTemplate={itemTemplate} className="border-1 surface-border border-round" style={{ width: '200px', height: '200px' }} />
            </div>
            <div>
                <span className="font-bold block mb-2">150ms</span>
                <VirtualScroller items={items} itemSize={50} itemTemplate={itemTemplate} className="border-1 surface-border border-round" style={{ width: '200px', height: '200px' }} delay={150} />
            </div>
            <div>
                <span className="font-bold block mb-2">500ms</span>
                <VirtualScroller items={items} itemSize={50} itemTemplate={itemTemplate} className="border-1 surface-border border-round" style={{ width: '200px', height: '200px' }} delay={500} />
            </div>
        </div>
    );
}
