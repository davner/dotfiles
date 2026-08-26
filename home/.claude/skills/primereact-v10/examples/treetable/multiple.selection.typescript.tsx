import React, { useState, useEffect } from 'react';
import { TreeTable, TreeTableSelectionKeysType, TreeTableSelectionEvent } from 'primereact/treetable';
import { Column } from 'primereact/column';
import { TreeNode } from 'primereact/treenode';
import { InputSwitch, InputSwitchChangeEvent } from 'primereact/inputswitch';
import { NodeService } from './service/NodeService';

export default function MultipleRowsSelectionDemo() {
    const [nodes, setNodes] = useState<TreeNode[]>([]);
    const [selectedNodeKeys, setSelectedNodeKeys] = useState<TreeTableSelectionKeysType | null>(null);
    const [metaKey, setMetaKey] = useState<boolean>(true);

    useEffect(() => {
        NodeService.getTreeTableNodes().then((data) => setNodes(data));
    }, []);

    return (
        <div className="card">
            <div className="flex justify-content-center align-items-center mb-4 gap-2">
                <InputSwitch inputId="input-metakey" checked={metaKey} onChange={(e: InputSwitchChangeEvent) => setMetaKey(e.value)} />
                <label htmlFor="input-metakey">MetaKey</label>
            </div>
            <TreeTable value={nodes} selectionMode="multiple" selectionKeys={selectedNodeKeys} onSelectionChange={(e: TreeTableSelectionEvent) => setSelectedNodeKeys(e.value)} metaKeySelection={metaKey} tableStyle={{ minWidth: '50rem' }}>
                <Column field="name" header="Name" expander></Column>
                <Column field="size" header="Size"></Column>
                <Column field="type" header="Type"></Column>
            </TreeTable>
        </div>
    )
}
