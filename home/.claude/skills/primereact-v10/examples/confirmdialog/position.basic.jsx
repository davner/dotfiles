<Toast ref={toast} />
<ConfirmDialog />
<div className="flex flex-wrap justify-content-center gap-2 mb-2">
    <Button label="Left" icon="pi pi-arrow-right" onClick={() => confirm('left')} className="p-button-help" style={{ minWidth: '10rem' }} />
    <Button label="Right" icon="pi pi-arrow-left" onClick={() => confirm('right')} className="p-button-help" style={{ minWidth: '10rem' }} />
</div>
<div className="flex flex-wrap justify-content-center gap-2 mb-2">
    <Button label="TopLeft" icon="pi pi-arrow-down-right" onClick={() => confirm('top-left')} className="p-button-warning" style={{ minWidth: '10rem' }} />
    <Button label="Top" icon="pi pi-arrow-down" onClick={() => confirm('top')} className="p-button-warning" style={{ minWidth: '10rem' }} />
    <Button label="TopRight" icon="pi pi-arrow-down-left" onClick={() => confirm('top-right')} className="p-button-warning" style={{ minWidth: '10rem' }} />
</div>
<div className="flex flex-wrap justify-content-center gap-2">
    <Button label="BottomLeft" icon="pi pi-arrow-up-right" onClick={() => confirm('bottom-left')} className="p-button-success" style={{ minWidth: '10rem' }} />
    <Button label="Bottom" icon="pi pi-arrow-up" onClick={() => confirm('bottom')} className="p-button-success" style={{ minWidth: '10rem' }} />
    <Button label="BottomRight" icon="pi pi-arrow-up-left" onClick={() => confirm('bottom-right')} className="p-button-success" style={{ minWidth: '10rem' }} />
</div>
