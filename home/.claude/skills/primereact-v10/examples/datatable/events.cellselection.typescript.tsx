import React, { useState, useRef, useEffect } from 'react';
import { DataTable, DataTableSelectionChangeEvent, DataTableCellSelection, DataTableSelectEvent, DataTableUnselectEvent } from 'primereact/datatable';
import { Column } from 'primereact/column';
import { Toast } from 'primereact/toast'
import { ProductService } from './service/ProductService';

interface Product {
    id: string;
    code: string;
    name: string;
    description: string;
    image: string;
    price: number;
    category: string;
    quantity: number;
    inventoryStatus: string;
    rating: number;
}

export default function CellSelectEventsDemo() {
    const [products, setProducts] = useState<Product[]>([]);
    const [selectedCell, setSelectedCell] = useState<DataTableCellSelection<Product[]> | null>(null);
    const toast = useRef<Toast>(null);

    const onCellSelect = (event: DataTableCellClickEvent<Product[]>) => {
        toast.current?.show({ severity: 'info', summary: 'Cell Selected', detail: `Name: ${event.value}`, life: 3000 });
    };

    const onCellUnselect = (event: DataTableCellClickEvent<Product[]>) => {
        toast.current?.show({ severity: 'warn', summary: 'Cell Unselected', detail: `Name: ${event.value}`, life: 3000 });
    };

    useEffect(() => {
        ProductService.getProductsMini().then((data) => setProducts(data));
    }, []);

    return (
        <div className="card">
            <Toast ref={toast} />
            <DataTable value={products} cellSelection selectionMode="single" selection={selectedCell!} metaKeySelection={false}
                    onSelectionChange={(e) => {
                        const value = e.value as DataTableCellSelection<Product[]>;
                        setSelectedCell(value);
                    }}
                    onCellSelect={onCellSelect} onCellUnselect={onCellUnselect} tableStyle={{ minWidth: '50rem' }}>
                <Column field="code" header="Code"></Column>
                <Column field="name" header="Name"></Column>
                <Column field="category" header="Category"></Column>
                <Column field="quantity" header="Quantity"></Column>
            </DataTable>
        </div>
    );
}
