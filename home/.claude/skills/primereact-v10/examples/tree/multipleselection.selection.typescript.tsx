import React, { useState, useEffect } from 'react';
import { InputSwitch, InputSwitchChangeEvent } from 'primereact/inputswitch';
import { Tree, TreeMultipleSelectionKeys } from 'primereact/tree';
import { TreeNode } from 'primereact/treenode';
import { NodeService } from './service/NodeService';

export default function MultipleSelectionDemo() {
    const [nodes, setNodes] = useState<TreeNode[]>([]);
    const [selectedKeys, setSelectedKeys] = useState<TreeMultipleSelectionKeys | null>(null);
    const [metaKey, setMetaKey] = useState<boolean>(false);
    
    useEffect(() => {
        NodeService.getTreeNodes().then((data) => setNodes(data));
    }, []);

    return (
        <div className="card flex flex-column align-items-center justify-content-center">
            <div className="flex align-items-center mb-4 gap-2">
                <InputSwitch inputId="input-metakey" checked={metaKey} onChange={(e: InputSwitchChangeEvent) => setMetaKey(e.value)} />
                <label htmlFor="input-metakey">MetaKey</label>
            </div>
            <Tree value={nodes} metaKeySelection={metaKey} selectionMode="multiple" selectionKeys={selectedKeys} onSelectionChange={(e) => setSelectedKeys(e.value)} className="w-full md:w-30rem" />
        </div>
    )
}
