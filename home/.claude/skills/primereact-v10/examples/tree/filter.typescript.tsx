import React, { useState, useEffect } from 'react';
import { Tree } from 'primereact/tree';
import { TreeNode } from 'primereact/treenode';
import { NodeService } from './service/NodeService';

export default function FilterDemo() {
    const [nodes, setNodes] = useState<TreeNode[]>([]);
    
    useEffect(() => {
        NodeService.getTreeNodes().then((data) => setNodes(data));
    }, []);

    return (
        <div className="card flex flex-wrap justify-content-center gap-5">
            <Tree value={nodes} filter filterMode="lenient" filterPlaceholder="Lenient Filter" className="w-full md:w-30rem" />
            <Tree value={nodes} filter filterMode="strict" filterPlaceholder="Strict Filter" className="w-full md:w-30rem" />
        </div>
    )
}
