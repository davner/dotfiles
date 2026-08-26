<Galleria ref={galleria} value={images} numVisible={9} style={{ maxWidth: '50%' }} 
    circular fullScreen showItemNavigators showThumbnails={false} item={itemTemplate} thumbnail={thumbnailTemplate} />

<Button label="Show" icon="pi pi-external-link" onClick={() => galleria.current.show()} />
