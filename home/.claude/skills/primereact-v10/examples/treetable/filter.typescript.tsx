import React, { useState, useEffect } from 'react';
import { TreeTable } from 'primereact/treetable';
import { Column } from 'primereact/column';
import { InputText } from 'primereact/inputtext';
import { IconField } from 'primereact/iconfield';
import { InputIcon } from 'primereact/inputicon';
import { SelectButton } from 'primereact/selectbutton';
import { TreeNode } from 'primereact/treenode';
import { NodeService } from './service/NodeService';

interface FilterModeOption {
    label: string;
    value: string;
}

export default function FilterDemo() {
    const [nodes, setNodes] = useState<TreeNode[]>([]);
    const [globalFilter, setGlobalFilter] = useState<string>('');
    const [filterMode, setFilterMode] = useState<'lenient' | 'strict'>('lenient');
    const [filterOptions] = useState<FilterModeOption[]>([
        { label: 'Lenient', value: 'lenient' },
        { label: 'Strict', value: 'strict' }
    ]);

    useEffect(() => {
        NodeService.getTreeTableNodes().then((data) => setNodes(data));
    }, []);

    const getHeader = () => {
        return (
            <div className="flex justify-content-end">
                <IconField iconPosition="left">
                    <InputIcon className="pi pi-search" />
                    <InputText type="search" onInput={(e) => setGlobalFilter(e.target.value)} placeholder="Global Search" />
                </IconField>
            </div>
        );
    };

    let header = getHeader();

    return (
        <div className="card">
            <div className="flex justify-content-center mb-4">
                <SelectButton value={filterMode} onChange={(e) => setFilterMode(e.value)} options={filterOptions} />
            </div>
            <TreeTable value={nodes} globalFilter={globalFilter} header={header} filterMode={filterMode} tableStyle={{ minWidth: '50rem' }}>
                <Column field="name" header="Name" expander filter filterPlaceholder="Filter by name"></Column>
                <Column field="size" header="Size" filter filterPlaceholder="Filter by size"></Column>
                <Column field="type" header="Type" filter filterPlaceholder="Filter by type"></Column>
            </TreeTable>
        </div>
    )
}
