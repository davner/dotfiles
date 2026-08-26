import React, { useState, useEffect, useRef } from 'react';
import { VirtualScroller, VirtualScrollerTemplateOptions, VirtualScrollerLazyEvent } from 'primereact/virtualscroller';
import { Skeleton } from 'primereact/skeleton';
import { classNames } from 'primereact/utils';

export default function LazyDemo() {
    const [lazyItems, setLazyItems] = useState<string[]>([]);
    const [lazyLoading, setLazyLoading] = useState<boolean>(true);
    const loadLazyTimeout = useRef(null);

    useEffect(() => {
        setLazyItems(Array.from({ length: 100000 }));
        setLazyLoading(false);
    }, []);

    const onLazyLoad = (event: VirtualScrollerLazyEvent) => {
        setLazyLoading(true);

        if (loadLazyTimeout.current) {
            clearTimeout(loadLazyTimeout.current);
        }

        //imitate delay of a backend call
        loadLazyTimeout.current = setTimeout(() => {
            const { first, last } = event;
            const _lazyItems = [...lazyItems];

            for (let i = first; i < last; i++) {
                _lazyItems[i] = `Item #${i}`;
            }

            setLazyItems(_lazyItems);
            setLazyLoading(false);
        }, Math.random() * 1000 + 250);
    };

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

    const loadingTemplate = (options: VirtualScrollerTemplateOptions) => {
        const className = classNames('flex align-items-center p-2', {
            odd: options.odd
        });

        return (
            <div className={className} style={{ height: '50px' }}>
                <Skeleton width={options.even ? '60%' : '50%'} height="1.3rem" />
            </div>
        );
    };

    return (
        <div className="card flex justify-content-center">
            <VirtualScroller items={lazyItems} itemSize={50} itemTemplate={itemTemplate} lazy onLazyLoad={onLazyLoad} loadingTemplate={loadingTemplate}
                showLoader loading={lazyLoading} className="border-1 surface-border border-round" style={{ width: '200px', height: '200px' }} />
        </div>
    );
}
