<DataTable value={products} editMode="cell" tableStyle={{ minWidth: '50rem' }}>
    {columns.map(({ field, header }) => {
        return <Column key={field} field={field} header={header}
            style={{ width: '25%' }} body={field === 'price' && priceBodyTemplate}
            editor={(options) => cellEditor(options)} onCellEditComplete={onCellEditComplete} />;
    })}
</DataTable>
