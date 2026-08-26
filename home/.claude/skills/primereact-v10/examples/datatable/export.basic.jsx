<Button type="button" icon="pi pi-file" rounded onClick={() => exportCSV(false)} data-pr-tooltip="CSV" />
<Button type="button" icon="pi pi-file-excel" severity="success" rounded onClick={exportExcel} data-pr-tooltip="XLS" />
<Button type="button" icon="pi pi-file-pdf" severity="warning" rounded onClick={exportPdf} data-pr-tooltip="PDF" />

<DataTable ref={dt} value={products} header={header} tableStyle={{ minWidth: '50rem' }}>
    {cols.map((col, index) => (
        <Column key={index} field={col.field} header={col.header} />
    ))}
</DataTable>
