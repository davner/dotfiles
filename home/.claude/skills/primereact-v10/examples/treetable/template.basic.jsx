<TreeTable value={nodes} header={header} footer={footer} togglerTemplate={togglerTemplate} tableStyle={{ minWidth: '50rem' }}>
    <Column field="name" header="Name" expander></Column>
    <Column field="size" header="Size"></Column>
    <Column field="type" header="Type"></Column>
    <Column body={actionTemplate} headerClassName="w-10rem" />
</TreeTable>
