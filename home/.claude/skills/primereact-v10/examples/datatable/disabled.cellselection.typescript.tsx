import React, { useState, useEffect } from 'react';
import { DataTable, DataTableSelectionChangeEvent, DataTableCellSelection,
        DataTableDataSelectableEvent, DataTableCellClassNameOptions } from 'primereact/datatable';
import { Column } from 'primereact/column';
import { InputSwitch, InputSwitchChangeEvent } from 'primereact/inputswitch';
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

export default function DisabledCellSelectionDemo() {
    const [products, setProducts] = useState<Product[]>([]);
    const [selectedCell, setSelectedCell] = useState<DataTableCellSelection<Product[]> | null>(null);
    const [metaKey, setMetaKey] = useState<boolean>(true);

    const isCellSelectable = (event: DataTableDataSelectableEvent) => (event.data.field === 'category' && event.data.value === 'Fitness' ? false : true);

    const cellClassName = (data: any) => (data === 'Fitness' ? 'p-disabled' : '');

    useEffect(() => {
        ProductService.getProductsMini().then((data) => setProducts(data));
    }, []);

    return (
        <div className="card">
            <div className="flex justify-content-center align-items-center mb-4 gap-2">
                <InputSwitch inputId="input-metakey" checked={metaKey} onChange={(e: InputSwitchChangeEvent) => setMetaKey(e.value!)} />
                <label htmlFor="input-metakey">MetaKey</label>
            </div>
            <DataTable value={products} cellSelection selectionMode="single" selection={selectedCell!} metaKeySelection={metaKey}
                    onSelectionChange={(e) => {
                        const value = e.value as DataTableCellSelection<Product[]>;
                        setSelectedCell(value);
                    }} 
                    isDataSelectable={isCellSelectable} cellClassName={cellClassName} tableStyle={{ minWidth: '50rem' }}>
                <Column field="code" header="Code"></Column>
                <Column field="name" header="Name"></Column>
                <Column field="category" header="Category"></Column>
                <Column field="quantity" header="Quantity"></Column>
            </DataTable>
        </div>
    );
}
