<TreeTable value={nodes} tableStyle={{ minWidth: '50rem' }}>
    <Column field="name" header="Name" expander style={{ height: '3.5rem' }}></Column>
    <Column field="size" header="Size" editor={sizeEditor} cellEditValidator={requiredValidator} style={{ height: '3.5rem' }}></Column>
    <Column field="type" header="Type" editor={typeEditor} style={{ height: '3.5rem' }}></Column>
</TreeTable>
