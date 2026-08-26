import React, { useState, useEffect } from "react";
import { TreeSelect, TreeSelectChangeEvent } from 'primereact/treeselect';
import { TreeNode } from 'primereact/treenode';
import { NodeService } from './service/NodeService';

export default function CheckboxDemo() {
    const [nodes, setNodes] = useState<TreeNode[] | null>(null);
    const [selectedNodeKeys, setSelectedNodeKeys] = useState<string[]>(null);
    
    useEffect(() => {
        NodeService.getTreeNodes().then((data) => setNodes(data));
    }, []); // eslint-disable-line react-hooks/exhaustive-deps

    return (
        <div className="card flex justify-content-center">
            <TreeSelect value={selectedNodeKeys} onChange={(e: TreeSelectChangeEvent) => setSelectedNodeKeys(e.value)} options={nodes} 
                metaKeySelection={false} className="md:w-20rem w-full" selectionMode="checkbox" display="chip" placeholder="Select Items"></TreeSelect>
        </div>
    );
}
