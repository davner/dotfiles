<span className="font-bold text-4xl mb-5">{count}</span>
<div className="flex flex-wrap gap-3">
    <Button icon="pi pi-plus" className="p-button-outlined p-button-rounded p-button-success" onClick={increment}></Button>
    <Button icon="pi pi-minus" className="p-button-outlined p-button-rounded" onClick={decrement}></Button>
    <Button icon="pi pi-times" className="p-button-outlined p-button-rounded p-button-danger" onClick={reset}></Button>
</div>
