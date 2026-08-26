import React, { useState } from 'react';
import { DataTable } from 'primereact/datatable';
import { Column } from 'primereact/column';
import { Skeleton } from 'primereact/skeleton';
import { VirtualScrollerLazyEvent, VirtualScrollerLoadingTemplateOptions } from 'primereact/virtualscroller';
import { CarService } from './service/CarService';

interface Car {
    id: number;
    vin: string;
    brand: string;
    color: string;
    year: number;
}

export default function LazyVirtualScrollDemo() {
    const cars: Car[] = Array.from({ length: 100000 }).map((_, i) => CarService.generateCar(i + 1));
    const [virtualCars, setVirtualCars] = useState<Car[]>(Array.from({ length: 100000 }));
    const [lazyLoading, setLazyLoading] = useState<boolean>(false);
    let loadLazyTimeout = null;

    const loadCarsLazy = (event: VirtualScrollerLazyEvent) => {
        !lazyLoading && setLazyLoading(true);

        if (loadLazyTimeout) {
            clearTimeout(loadLazyTimeout);
        }

        //simulate remote connection with a timeout
        loadLazyTimeout = setTimeout(() => {
            let _virtualCars = [...virtualCars];
            let { first, last } = event;

            //load data of required page
            const loadedCars = cars.slice(first, last);

            //populate page of virtual cars
            Array.prototype.splice.apply(_virtualCars, [...[first, last - first], ...loadedCars]);

            setVirtualCars(_virtualCars);
            setLazyLoading(false);
        }, Math.random() * 1000 + 250);
    };

    const loadingTemplate = (options: VirtualScrollerLoadingTemplateOptions) => {
        return (
            <div className="flex align-items-center" style={{ height: '17px', flexGrow: '1', overflow: 'hidden' }}>
                <Skeleton width={options.cellEven ? (options.field === 'year' ? '30%' : '40%') : '60%'} height="1rem" />
            </div>
        );
    };

    return (
        <div className="card">
            <DataTable value={virtualCars} scrollable scrollHeight="400px"
                virtualScrollerOptions={{ lazy: true, onLazyLoad: loadCarsLazy, itemSize: 46, delay: 200, showLoader: true, loading: lazyLoading, loadingTemplate }}
                tableStyle={{ minWidth: '50rem' }}>
                <Column field="id" header="Id" style={{ width: '20%' }}></Column>
                <Column field="vin" header="Vin" style={{ width: '20%' }}></Column>
                <Column field="year" header="Year" style={{ width: '20%' }}></Column>
                <Column field="brand" header="Brand" style={{ width: '20%' }}></Column>
                <Column field="color" header="Color" style={{ width: '20%' }}></Column>
            </DataTable>
        </div>
    );
}
