import React, { useState, useEffect, useRef } from 'react';
import { DataTable } from 'primereact/datatable';
import { Column } from 'primereact/column';
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

interface ColumnMeta {
    field: string;
    header: string;
}

export default function ReorderDemo() {
    const [products, setProducts] = useState<Product[]>([]);
    const columns: ColumnMeta[] = [
        { field: 'code', header: 'Code' },
        { field: 'name', header: 'Name' },
        { field: 'category', header: 'Category' },
        { field: 'quantity', header: 'Quantity' }
    ];

    useEffect(() => {
        ProductService.getProductsMini().then((data) => setProducts(data));
    }, []);

    const dynamicColumns = columns.map((col, i) => {
        return <Column key={col.field} columnKey={col.field} field={col.field} header={col.header} />;
    });

    return (
        <div className="card">
            <DataTable value={products} reorderableColumns reorderableRows onRowReorder={(e) => setProducts(e.value)} tableStyle={{ minWidth: '50rem' }}>
                <Column rowReorder style={{ width: '3rem' }} />
                {dynamicColumns}
            </DataTable>
        </div>
    );
}
