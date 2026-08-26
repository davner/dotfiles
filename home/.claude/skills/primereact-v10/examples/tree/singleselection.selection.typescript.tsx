import React, { useState, useEffect } from 'react';
import { Tree } from 'primereact/tree';
import { TreeNode } from 'primereact/treenode';
import { NodeService } from './service/NodeService';

export default function SingleSelectionDemo() {
    const [nodes, setNodes] = useState<TreeNode[]>([]);
    const [selectedKey, setSelectedKey] = useState<string>('');
    
    useEffect(() => {
        NodeService.getTreeNodes().then((data) => setNodes(data));
    }, []);

    return (
        <div className="card flex justify-content-center">
            <Tree value={nodes} selectionMode="single" selectionKeys={selectedKey} onSelectionChange={(e) => setSelectedKey(e.value)} className="w-full md:w-30rem" />
        </div>
    )
}
