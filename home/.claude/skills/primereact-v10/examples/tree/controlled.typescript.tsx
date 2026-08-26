import React, { useState, useEffect } from 'react';
import { Tree, TreeExpandedKeysType } from 'primereact/tree';
import { TreeNode } from 'primereact/treenode';
import { Button } from 'primereact/button';
import { NodeService } from './service/NodeService';

export default function ControlledDemo() {
    const [nodes, setNodes] = useState<TreeNode[]>([]);
    const [expandedKeys, setExpandedKeys] = useState<TreeExpandedKeysType>({'0': true, '0-0': true});

    const expandAll = () => {
        let _expandedKeys = {};

        for (let node of nodes) {
            expandNode(node, _expandedKeys);
        }

        setExpandedKeys(_expandedKeys);
    };

    const collapseAll = () => {
        setExpandedKeys({});
    };

    const expandNode = (node: TreeNode, _expandedKeys: TreeExpandedKeysType) => {
        if (node.children && node.children.length) {
            _expandedKeys[node.key] = true;

            for (let child of node.children) {
                expandNode(child, _expandedKeys);
            }
        }
    };

    useEffect(() => {
        NodeService.getTreeNodes().then((data) => setNodes(data));
    }, []);
    
    return (
        <div className="card flex flex-column align-items-center">
            <div className="flex flex-wrap gap-2 mb-4">
                <Button type="button" icon="pi pi-plus" label="Expand All" onClick={expandAll} />
                <Button type="button" icon="pi pi-minus" label="Collapse All" onClick={collapseAll} />
            </div>

            <Tree value={nodes} expandedKeys={expandedKeys} onToggle={(e) => setExpandedKeys(e.value)} className="w-full md:w-30rem" />
        </div>
    )
}
