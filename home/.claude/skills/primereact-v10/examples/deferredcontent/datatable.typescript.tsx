import React, { useState, useRef } from 'react';
import { DeferredContent } from 'primereact/deferredcontent';
import { DataTable } from 'primereact/datatable';
import { Column } from 'primereact/column';
import { Toast } from 'primereact/toast';
import { ProductService } from './service/ProductService';

export default function DataTableDemo() {
    const toast = useRef<Toast>(null);
    const [products, setProducts] = useState(null);

    const onDataLoad = () => {
        ProductService.getProductsSmall().then(data => setProducts(data));
        toast.current.show({ severity: 'success', summary: 'Data Initialized', detail: 'Render Completed' });
    }

    return (
        <div className="card">
            <p style={{marginBottom: '70rem', textAlign: 'center'}}>Scroll down to lazy load a DataTable.</p>
            <Toast ref={toast} />
            <DeferredContent onLoad={onDataLoad}>
                <DataTable value={products}>
                    <Column field="code" header="Code"></Column>
                    <Column field="name" header="Name"></Column>
                    <Column field="category" header="Category"></Column>
                    <Column field="quantity" header="Quantity"></Column>
                </DataTable>
            </DeferredContent>
        </div>
    )
}
