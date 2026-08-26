import React, { useState, useEffect } from 'react';
import { TreeTable } from 'primereact/treetable';
import { Column } from 'primereact/column';
import { TreeNode } from 'primereact/treenode';
import { NodeService } from './service/NodeService';

export default function FrozenColumnsDemo() {
    const [nodes, setNodes] = useState<TreeNode[]>([]);

    useEffect(() => {
        NodeService.getTreeTableNodes().then(data => setNodes(data));
    }, []);

    return (
        <div className="card">
            <TreeTable value={nodes} scrollable frozenWidth="200px" scrollHeight="250px">
                <Column field="name" header="Name" expander frozen style={{ width: '250px', height: '57px' }}></Column>
                <Column field="size" header="Size" style={{ width: '250px', height: '57px' }} columnKey="size_0"></Column>
                <Column field="type" header="Type" style={{ width: '250px', height: '57px' }} columnKey="type_0"></Column>
                <Column field="size" header="Size" style={{ width: '250px', height: '57px' }} columnKey="size_1"></Column>
                <Column field="type" header="Type" style={{ width: '250px', height: '57px' }} columnKey="type_1"></Column>
                <Column field="size" header="Size" style={{ width: '250px', height: '57px' }} columnKey="size_2"></Column>
                <Column field="type" header="Type" style={{ width: '250px', height: '57px' }} columnKey="type_2"></Column>
            </TreeTable>
        </div>
    );
}
