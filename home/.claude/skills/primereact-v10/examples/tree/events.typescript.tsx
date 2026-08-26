import React, { useState, useEffect, useRef } from 'react';
import { Tree, TreeEventNodeEvent } from 'primereact/tree';
import { Toast } from 'primereact/toast';
import { TreeNode } from "primereact/treenode";
import { NodeService } from './service/NodeService';

export default function EventsDemo() {
    const [nodes, setNodes] = useState<TreeNode[]>([]);
    const [selectedNodeKey, setSelectedNodeKey] = useState<string>('');
    const toast = useRef<Toast>(null);
    
    useEffect(() => {
        NodeService.getTreeNodes().then((data) => setNodes(data));
    }, []);

    const onExpand = (event: TreeEventNodeEvent) => {
        toast.current.show({ severity: 'success', summary: 'Node Expanded', detail: event.node.label });
    };

    const onCollapse = (event: TreeEventNodeEvent) => {
        toast.current.show({ severity: 'warn', summary: 'Node Collapsed', detail: event.node.label });
    };

    const onSelect = (event: TreeEventNodeEvent) => {
        toast.current.show({ severity: 'info', summary: 'Node Selected', detail: event.node.label });
    };

    const onUnselect = (event: TreeEventNodeEvent) => {
        toast.current.show({ severity: 'info', summary: 'Node Unselected', detail: event.node.label });
    };

    return (
        <>
            <Toast ref={toast} />
            <div className="card flex justify-content-center">
                <Tree value={nodes} selectionMode="single" selectionKeys={selectedNodeKey} onSelectionChange={(e) => setSelectedNodeKey(e.value)} 
                    onExpand={onExpand} onCollapse={onCollapse} onSelect={onSelect} onUnselect={onUnselect} className="w-full md:w-30rem" />
            </div>
        </>
    )
}
