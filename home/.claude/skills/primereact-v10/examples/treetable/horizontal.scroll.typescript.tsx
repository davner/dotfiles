import React, { useState, useEffect } from 'react';
import { TreeTable } from 'primereact/treetable';
import { Column } from 'primereact/column';
import { TreeNode } from 'primereact/treenode';
import { NodeService } from './service/NodeService';

export default function HorizontalScrollDemo() {
    const [nodes, setNodes] = useState<TreeNode[]>([]);
    
    useEffect(() => {
        NodeService.getTreeTableNodes().then(data => setNodes(data));
    }, []);

    return (
        <div className="card">
            <TreeTable value={nodes} scrollable scrollHeight="200px">
                <Column field="name" header="Name" expander style={{ width: '250px' }}></Column>
                <Column field="size" header="Size" style={{ width: '250px' }}></Column>
                <Column field="type" header="Type 2" style={{ width: '250px' }}></Column>
                <Column field="size" header="Size 2" style={{ width: '250px' }}></Column>
                <Column field="type" header="Type 3" style={{ width: '250px' }}></Column>
                <Column field="size" header="Size 3" style={{ width: '250px' }}></Column>
            </TreeTable>
        </div>
    );
}
