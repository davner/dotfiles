import React, {useState, useEffect } from 'react';
import { TreeTable } from 'primereact/treetable';
import { Column } from 'primereact/column';
import { MultiSelect, MultiSelectChangeEvent } from 'primereact/multiselect';
import { TreeNode } from 'primereact/treenode';
import { NodeService } from './service/NodeService';

interface ColumnMeta {
    field: string;
    header: string;
}

export default function ColumnToggleDemo() {
    let columns: ColumnMeta[] = [
        { field: 'size', header: 'Size' },
        { field: 'type', header: 'Type' }
    ];
    const [nodes, setNodes] = useState<TreeNode[]>([]);
    const [visibleColumns, setVisibleColumns] = useState<ColumnMeta>(columns);

    useEffect(() => {
        NodeService.getTreeTableNodes().then((data) => setNodes(data));
    }, []);

    const onColumnToggle = (event: MultiSelectChangeEvent) => {
        let selectedColumns = event.value;
        let orderedSelectedColumns = columns.filter((col) => selectedColumns.some((sCol) => sCol.field === col.field));

        setVisibleColumns(orderedSelectedColumns);
    };

    const header = <MultiSelect value={visibleColumns} options={columns} onChange={onColumnToggle} optionLabel="header" className="w-full sm:w-16rem" display="chip" />;

    return (
        <div className="card">
            <TreeTable value={nodes} header={header} tableStyle={{ minWidth: '50rem' }}>
                <Column key="name" field="name" header="Name" expander />
                {visibleColumns.map((col) => (
                    <Column key={col.field} field={col.field} header={col.header} />
                ))}
            </TreeTable>
        </div>
    );
}
