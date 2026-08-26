<Galleria ref={galleria} value={images} responsiveOptions={responsiveOptions} numVisible={9} style={{ maxWidth: '50%' }} 
    circular fullScreen showItemNavigators item={itemTemplate} thumbnail={thumbnailTemplate} />

<Button label="Show" icon="pi pi-external-link" onClick={() => galleria.current.show()} />
