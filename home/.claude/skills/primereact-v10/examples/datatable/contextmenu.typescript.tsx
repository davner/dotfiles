import React, { useState, useEffect, useRef } from 'react';
import { DataTable } from 'primereact/datatable';
import { Column } from 'primereact/column';
import { ContextMenu } from 'primereact/contextmenu';
import { Toast } from 'primereact/toast';
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

export default function ContextMenuDemo() {
    const [products, setProducts] = useState<Product[]>([]);
    const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
    const toast = useRef<Toast>(null);
    const cm = useRef<ContextMenu>(null);
    const menuModel = [
        { label: 'View', icon: 'pi pi-fw pi-search', command: () => viewProduct(selectedProduct) },
        { label: 'Delete', icon: 'pi pi-fw pi-times', command: () => deleteProduct(selectedProduct) }
    ];

    useEffect(() => {
        ProductService.getProductsMini().then((data) => setProducts(data));
    }, []); // eslint-disable-line react-hooks/exhaustive-deps

    const viewProduct = (product) => {
        toast.current.show({ severity: 'info', summary: 'Product Selected', detail: product.name });
    };

    const deleteProduct = (product) => {
        let _products = [...products];

        _products = _products.filter((p) => p.id !== product.id);

        toast.current.show({ severity: 'error', summary: 'Product Deleted', detail: product.name });
        setProducts(_products);
    };

    const formatCurrency = (value) => {
        return value.toLocaleString('en-US', { style: 'currency', currency: 'USD' });
    };

    const priceBodyTemplate = (rowData) => {
        return formatCurrency(rowData.price);
    };

    return (
        <div className="card">
            <Toast ref={toast} />

            <ContextMenu model={menuModel} ref={cm} onHide={() => setSelectedProduct(null)} />
            <DataTable value={products} onContextMenu={(e) => cm.current.show(e.originalEvent)} contextMenuSelection={selectedProduct} onContextMenuSelectionChange={(e) => setSelectedProduct(e.value)} tableStyle={{ minWidth: '50rem' }}>
                <Column field="code" header="Code"></Column>
                <Column field="name" header="Name"></Column>
                <Column field="category" header="Category"></Column>
                <Column field="price" header="Price" body={priceBodyTemplate} />
            </DataTable>
        </div>
    );
}
