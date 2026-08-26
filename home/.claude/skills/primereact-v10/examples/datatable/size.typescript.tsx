import React, { useState, useEffect } from 'react';
import { DataTable } from 'primereact/datatable';
import { Column } from 'primereact/column';
import { SelectButton, SelectButtonChangeEvent } from 'primereact/selectbutton';
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

interface SizeOption {
    label: string;
    value: string;
}

export default function SizeDemo() {
    const [products, setProducts] = useState<Product[]>([]);
    const [sizeOptions] = useState<SizeOption[]>([
        { label: 'Small', value: 'small' },
        { label: 'Normal', value: 'normal' },
        { label: 'Large', value: 'large' }
    ]);
    const [size, setSize] = useState<string>(sizeOptions[1].value);

    useEffect(() => {
        ProductService.getProductsMini().then((data) => setProducts(data));
    }, []);

    return (
        <div className="card">
            <div className="flex justify-content-center mb-4">
                <SelectButton value={size} onChange={(e: SelectButtonChangeEvent) => setSize(e.value)} options={sizeOptions} />
            </div>
            <DataTable value={products} size={size} tableStyle={{ minWidth: '50rem' }}>
                <Column field="code" header="Code"></Column>
                <Column field="name" header="Name"></Column>
                <Column field="category" header="Category"></Column>
                <Column field="quantity" header="Quantity"></Column>
            </DataTable>
        </div>
    );
}
