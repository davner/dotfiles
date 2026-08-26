import React, { useState } from "react";
import { Paginator, PaginatorPageChangeEvent } from 'primereact/paginator';

export default function ImagesDemo() {
    const [first, setFirst] = useState<number>(0);

    const onPageChange = (event: PaginatorPageChangeEvent) => {
        setFirst(event.first);
    };

    return (
        <div className="card">
            <Paginator first={first} rows={1} totalRecords={12} onPageChange={onPageChange} template="FirstPageLink PrevPageLink CurrentPageReport NextPageLink LastPageLink" />

            <div className="p-3 text-center">
                <img alt={first} src={`https://primefaces.org/cdn/primereact/images/nature/nature${first + 1}.jpg`} className="shadow-2 border-round max-w-full" />
            </div>
        </div>
    );
}
