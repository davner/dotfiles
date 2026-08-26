import React, { useState, useEffect, useRef } from 'react';
import { DataTable, DataTableRowToggleEvent, DataTableExpandedRows } from 'primereact/datatable';
import { Column } from 'primereact/column';
import { Tag } from 'primereact/tag';
import { CustomerService } from './service/CustomerService';

interface Country {
    name: string;
    code: string;
}

interface Representative {
    name: string;
    image: string;
}

interface Customer {
    id: number;
    name: string;
    country: Country;
    company: string;
    date: string;
    status: string;
    verified: boolean;
    activity: number;
    representative: Representative;
    balance: number;
}

export default function ExpandableRowGroupDemo() {
    const [customers, setCustomers] = useState<Customer[]>([]);
    const [expandedRows, setExpandedRows] = useState<DataTableExpandedRows | Customer[]>([]);

    useEffect(() => {
        CustomerService.getCustomersMedium().then((data) => setCustomers(data));
    }, []); // eslint-disable-line react-hooks/exhaustive-deps

    const headerTemplate = (data: Customer) => {
        return (
            <React.Fragment>
                <img alt={data.representative.name} src={`https://primefaces.org/cdn/primereact/images/avatar/${data.representative.image}`} width="32" style={{ verticalAlign: 'middle' }} className="ml-2" />
                <span className="vertical-align-middle ml-2 font-bold line-height-3">{data.representative.name}</span>
            </React.Fragment>
        );
    };

    const footerTemplate = (data: Customer) => {
        return (
            <React.Fragment>
                <td colSpan={5}>
                    <div className="flex justify-content-end font-bold w-full">Total Customers: {calculateCustomerTotal(data.representative.name)}</div>
                </td>
            </React.Fragment>
        );
    };

    const countryBodyTemplate = (rowData: Customer) => {
        return (
            <div className="flex align-items-center gap-2">
                <img alt={rowData.country.name} src="https://primefaces.org/cdn/primereact/images/flag/flag_placeholder.png" className={`flag flag-${rowData.country.code}`} style={{ width: '24px' }} />
                <span>{rowData.country.name}</span>
            </div>
        );
    };

    const statusBodyTemplate = (rowData: Customer) => {
        return <Tag value={rowData.status} severity={getSeverity(rowData.status)} />;
    };

    const calculateCustomerTotal = (name: string) => {
        let total = 0;

        if (customers) {
            for (let customer of customers) {
                if (customer.representative.name === name) {
                    total++;
                }
            }
        }

        return total;
    };

    const getSeverity = (status: string) => {
        switch (status) {
            case 'unqualified':
                return 'danger';

            case 'qualified':
                return 'success';

            case 'new':
                return 'info';

            case 'negotiation':
                return 'warning';

            case 'renewal':
                return null;
        }
    };

    return (
        <div className="card">
            <DataTable value={customers} rowGroupMode="subheader" groupRowsBy="representative.name"
                    sortMode="single" sortField="representative.name" sortOrder={1}
                    expandableRowGroups expandedRows={expandedRows} onRowToggle={(e: DataTableRowToggleEvent) => setExpandedRows(e.data)}
                    rowGroupHeaderTemplate={headerTemplate} rowGroupFooterTemplate={footerTemplate} tableStyle={{ minWidth: '50rem' }}>
                <Column field="name" header="Name" style={{ width: '20%' }}></Column>
                <Column field="country" header="Country" body={countryBodyTemplate} style={{ width: '20%' }}></Column>
                <Column field="company" header="Company" style={{ width: '20%' }}></Column>
                <Column field="status" header="Status" body={statusBodyTemplate} style={{ width: '20%' }}></Column>
                <Column field="date" header="Date" style={{ width: '20%' }}></Column>
            </DataTable>
        </div>
    );
        }
