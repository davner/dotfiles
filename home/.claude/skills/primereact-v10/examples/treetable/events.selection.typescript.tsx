import React, { useState, useRef, useEffect } from 'react';
import { TreeTable, TreeTableSelectionEvent } from 'primereact/treetable';
import { Column } from 'primereact/column';
import { InputSwitch } from 'primereact/inputswitch';
import { Toast } from 'primereact/toast';
import { TreeNode } from 'primereact/treenode';
import { NodeService } from './service/NodeService';

export default function SingleRowSelectionDemo() {
    const [nodes, setNodes] = useState<TreeNode[]>([]);
    const [selectedNodeKey, setSelectedNodeKey] = useState<string | null>(null);
    const toast = useRef(null);

    const onSelect = (event) => {
        toast.current.show({ severity: 'info', summary: 'Node Selected', detail: event.node.data.name });
    };

    const onUnselect = (event) => {
        toast.current.show({ severity: 'warn', summary: 'Node Unselected', detail: event.node.data.name });
    };

    useEffect(() => {
        NodeService.getTreeTableNodes().then((data) => setNodes(data));
    }, []);

    return (
        <div className="card">
            <Toast ref={toast} />
            <TreeTable value={nodes} selectionMode="single" selectionKeys={selectedNodeKey} onSelectionChange={(e: TreeTableSelectionEvent) => setSelectedNodeKey(e.value)} metaKeySelection={false} onSelect={onSelect} onUnselect={onUnselect} tableStyle={{ minWidth: '50rem' }}>
                <Column field="name" header="Name" expander></Column>
                <Column field="size" header="Size"></Column>
                <Column field="type" header="Type"></Column>
            </TreeTable>
        </div>
    )
}
