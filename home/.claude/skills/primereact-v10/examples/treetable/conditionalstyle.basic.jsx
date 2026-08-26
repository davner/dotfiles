<TreeTable value={nodes} rowClassName={rowClassName} tableStyle={{ minWidth: '50rem' }}>
    <Column field="name" header="Name" expander></Column>
    <Column field="size" header="Size" body={sizeTemplate}></Column>
    <Column field="type" header="Type"></Column>
</TreeTable>
