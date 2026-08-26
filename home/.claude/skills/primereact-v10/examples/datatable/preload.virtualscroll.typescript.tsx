import React from 'react';
import { DataTable } from 'primereact/datatable';
import { Column } from 'primereact/column';
import { CarService } from './service/CarService';

interface Car {
    id: number;
    vin: string;
    brand: string;
    color: string;
    year: number;
}

export default function PreloadVirtualScrollDemo() {
    const cars: Car[] = Array.from({ length: 100000 }).map((_, i) => CarService.generateCar(i + 1));

    return (
        <div className="card">
            <DataTable value={cars} scrollable scrollHeight="400px" virtualScrollerOptions={{ itemSize: 46 }} tableStyle={{ minWidth: '50rem' }}>
                <Column field="id" header="Id" style={{ width: '20%' }}></Column>
                <Column field="vin" header="Vin" style={{ width: '20%' }}></Column>
                <Column field="year" header="Year" style={{ width: '20%' }}></Column>
                <Column field="brand" header="Brand" style={{ width: '20%' }}></Column>
                <Column field="color" header="Color" style={{ width: '20%' }}></Column>
            </DataTable>
        </div>
    );
}
