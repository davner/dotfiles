import React, { useState, useEffect } from 'react';
import { TreeTable } from 'primereact/treetable';
import { Column } from 'primereact/column';
import { TreeNode } from 'primereact/column';
import { NodeService } from './service/NodeService';

export default function ConditionalStyleDemo() {
    const [nodes, setNodes] = useState<TreeNode[]>([]);

    useEffect(() => {
        NodeService.getTreeTableNodes().then(data => setNodes(data));
    }, []);

    const sizeTemplate = (node: TreeNode) => {
        let size = node.data.size;
        let fontWeight = parseInt(size, 10) > 75 ? 'bold' : 'normal';

        return <span style={{ fontWeight: fontWeight }}>{size}</span>;
    }

    const rowClassName = (node: TreeNode) => {
        return { 'p-highlight': (node.children && node.children.length === 3) };
    }

    return (
        <div className="card">
            <TreeTable value={nodes} rowClassName={rowClassName} tableStyle={{ minWidth: '50rem' }}>
                <Column field="name" header="Name" expander></Column>
                <Column field="size" header="Size" body={sizeTemplate}></Column>
                <Column field="type" header="Type"></Column>
            </TreeTable>
        </div>
    );
}
