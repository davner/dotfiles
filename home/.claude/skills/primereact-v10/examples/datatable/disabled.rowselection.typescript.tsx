import React, { useState, useEffect } from 'react';
import { DataTable, DataTableSelectionChangeEvent, DataTableDataSelectableEvent } from 'primereact/datatable';
import { Column } from 'primereact/column';
import { ProductService } from './service/ProductService';

interface Product {
    id?: string;
    code?: string;
    name?: string;
    description?: string;
    image?: string;
    price?: number;
    category?: string;
    quantity?: number;
    inventoryStatus?: string;
    rating?: number;
}

export default function DisabledRowSelectionDemo() {
    const [products, setProducts] = useState<Product[]>([]);
    const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);

    const isSelectable = (data: Product) => data.quantity >= 10;

    const isRowSelectable = (event: DataTableDataSelectableEvent) => (event.data ? isSelectable(event.data) : true);

    const rowClassName = (data: Product) => (isSelectable(data) ? '' : 'p-disabled');

    useEffect(() => {
        ProductService.getProductsMini().then((data) => setProducts(data));
    }, []);

    return (
        <div className="card">
            <DataTable value={products} selectionMode="single" selection={selectedProduct!}
                    onSelectionChange={(e) => setSelectedProduct(e.value)} dataKey="id" isDataSelectable={isRowSelectable} rowClassName={rowClassName} tableStyle={{ minWidth: '50rem' }}>
                <Column field="code" header="Code"></Column>
                <Column field="name" header="Name"></Column>
                <Column field="category" header="Category"></Column>
                <Column field="quantity" header="Quantity"></Column>
            </DataTable>
        </div>
    );
}
