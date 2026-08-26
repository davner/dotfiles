import React, { useState, useEffect } from 'react';
import { TreeTable } from 'primereact/treetable';
import { Column } from 'primereact/column';
import { TreeNode } from 'primereact/treenode';
import { NodeService } from './service/NodeService';

interface ColumnMeta {
    field: string;
    header: string;
}

export default function DynamicColumnsDemo() {
    const [nodes, setNodes] = useState<TreeNode[]>([]);
    const columns: Column[] = [
        { field: 'name', header: 'Name', expander: true },
        { field: 'size', header: 'Type' },
        { field: 'type', header: 'Size' }
    ];

    useEffect(() => {
        NodeService.getTreeTableNodes().then((data) => setNodes(data));
    }, []);

    return (
        <div className="card">
            <TreeTable value={nodes} tableStyle={{ minWidth: '50rem' }}>
                {columns.map((col, i) => (
                    <Column key={col.field} field={col.field} header={col.header} expander={col.expander} />
                ))}
            </TreeTable>
        </div>
    );
}
