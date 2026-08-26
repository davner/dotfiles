import React, { useState, useEffect } from 'react';
import { DataTable } from 'primereact/datatable';
import { Column, ColumnBodyOptions } from 'primereact/column';
import { Button } from 'primereact/button';
import { CustomerService } from './service/CustomerService';

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

export default function FrozenRowsDemo() {
    const [customers, setCustomers] = useState<Customer[]>([]);
    const [lockedCustomers, setLockedCustomers] = useState<Customer[]>([]);

    useEffect(() => {
        CustomerService.getCustomersMedium().then((data) => setCustomers(data));

        setLockedCustomers([
            {
                id: 5135,
                name: 'Geraldine Bisset',
                country: {
                    name: 'France',
                    code: 'fr'
                },
                company: 'Bisset Group',
                status: 'proposal',
                date: '2019-05-05',
                activity: 0,
                representative: {
                    name: 'Amy Elsner',
                    image: 'amyelsner.png'
                }
            }
        ]);
    }, []);

    const lockTemplate = (rowData: Customer, options: ColumnBodyOptions) => {
        const icon = options.frozenRow ? 'pi pi-lock' : 'pi pi-lock-open';
        const disabled = options.frozenRow ? false : lockedCustomers.length >= 2;

        return <Button type="button" icon={icon} disabled={disabled} className="p-button-sm p-button-text" onClick={() => toggleLock(rowData, options.frozenRow, options.rowIndex)} />;
    };

    const toggleLock = (data: Customer, frozen: boolean, index: number) => {
        let _lockedCustomers, _unlockedCustomers;

        if (frozen) {
            _lockedCustomers = lockedCustomers.filter((c, i) => i !== index);
            _unlockedCustomers = [...customers, data];
        } else {
            _unlockedCustomers = customers.filter((c, i) => i !== index);
            _lockedCustomers = [...lockedCustomers, data];
        }

        _unlockedCustomers.sort((val1, val2) => {
            return val1.id < val2.id ? -1 : 1;
        });

        setLockedCustomers(_lockedCustomers);
        setCustomers(_unlockedCustomers);
    };

    return (
        <div className="card">
            <DataTable value={customers} frozenValue={lockedCustomers} scrollable scrollHeight="400px" tableStyle={{ minWidth: '50rem' }}>
                <Column field="name" header="Name"></Column>
                <Column field="country.name" header="Country"></Column>
                <Column field="representative.name" header="Representative"></Column>
                <Column field="status" header="Status"></Column>
                <Column style={{ flex: '0 0 4rem' }} body={lockTemplate}></Column>
            </DataTable>
        </div>
    );
}
