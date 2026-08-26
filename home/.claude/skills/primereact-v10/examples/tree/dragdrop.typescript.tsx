import React, { useState, useEffect } from 'react';
import { Tree, TreeDragDropEvent } from 'primereact/tree';
import { TreeNode } from 'primereact/treenode';
import { NodeService } from './service/NodeService';

export default function DragDropDemo() {
    const [nodes, setNodes] = useState<TreeNode[]>([]);

    useEffect(() => {
        NodeService.getTreeNodes().then((data) => setNodes(data));
    }, []);

    return (
        <div className="card flex justify-content-center">
            <Tree value={nodes} dragdropScope="demo" onDragDrop={(e: TreeDragDropEvent) => setNodes(e.value)} className="w-full md:w-30rem" />
        </div>
    )
}
