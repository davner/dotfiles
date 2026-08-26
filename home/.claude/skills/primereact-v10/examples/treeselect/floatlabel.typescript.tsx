import React, { useState, useEffect } from "react";
import { TreeSelect, TreeSelectChangeEvent } from 'primereact/treeselect';
import { FloatLabel } from 'primereact/floatlabel';
import { TreeNode } from 'primereact/treenode';
import { NodeService } from './service/NodeService';

export default function FloatLabelDemo() {
    const [nodes, setNodes] = useState<TreeNode[] | null>(null);
    const [selectedNodeKey, setSelectedNodeKey] = useState<string>(null);

    useEffect(() => {
        NodeService.getTreeNodes().then((data) => setNodes(data));
    }, []);

    return (
        <div className="card flex justify-content-center">
            <FloatLabel className="w-full md:w-20rem">
                <TreeSelect inputId="treeselect" value={selectedNodeKey} options={nodes} onChange={(e : TreeSelectChangeEvent) => setSelectedNodeKey(e.value)}
                    className="w-full"></TreeSelect>
                <label htmlFor="treeselect">TreeSelect</label>
            </FloatLabel>
        </div>
    );
}
