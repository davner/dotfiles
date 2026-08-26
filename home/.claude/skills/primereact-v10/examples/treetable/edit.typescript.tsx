import React, { useState, useEffect } from 'react';
import { TreeTable } from 'primereact/treetable';
import { Column, ColumnEditorOptions, ColumnEvent } from 'primereact/column';
import { InputText } from 'primereact/inputtext';
import { TreeNode } from 'primereact/treenode';
import { NodeService } from './service/NodeService';

export default function EditDemo() {
    const [nodes, setNodes] = useState<TreeNode[]>([]);

    useEffect(() => {
        NodeService.getTreeTableNodes().then((data) => setNodes(data));
    }, []);

    const onEditorValueChange = (options: ColumnEditorOptions, value: string) => {
        let newNodes = JSON.parse(JSON.stringify(nodes));
        let editedNode = findNodeByKey(newNodes, options.node.key);

        editedNode.data[options.field] = value;

        setNodes(newNodes);
    };

    const findNodeByKey = (nodes: TreeNode[], key: string) => {
        let path = key.split('-');
        let node;

        while (path.length) {
            let list = node ? node.children : nodes;

            node = list[parseInt(path[0], 10)];
            path.shift();
        }

        return node;
    };

    const inputTextEditor = (options: ColumnEditorOptions) => {
        return <InputText type="text" value={options.rowData[options.field]} onChange={(e: React.ChangeEvent<HTMLInputElement>) => onEditorValueChange(options, e.target.value)} onKeyDown={(e) => e.stopPropagation()} />;
    };

    const sizeEditor = (options: ColumnEditorOptions) => {
        return inputTextEditor(options);
    };

    const typeEditor = (options: ColumnEditorOptions) => {
        return inputTextEditor(options);
    };

    const requiredValidator = (e: ColumnEvent) => {
        let props = e.columnProps;
        let value = props.node.data[props.field];

        return value && value.length > 0;
    };

    return (
        <div className="card">
            <TreeTable value={nodes} tableStyle={{ minWidth: '50rem' }}>
                <Column field="name" header="Name" expander style={{ height: '3.5rem' }}></Column>
                <Column field="size" header="Size" editor={sizeEditor} cellEditValidator={requiredValidator} style={{ height: '3.5rem' }}></Column>
                <Column field="type" header="Type" editor={typeEditor} style={{ height: '3.5rem' }}></Column>
            </TreeTable>
        </div>
    );
}
