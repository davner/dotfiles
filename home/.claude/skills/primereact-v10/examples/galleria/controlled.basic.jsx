<div>
    <Button icon="pi pi-minus" onClick={prev} className="p-button-secondary" />
    <Button icon="pi pi-plus" onClick={next} className="p-button-secondary ml-2" />
</div>

<Galleria value={images} activeIndex={activeIndex} onItemChange={(e) => setActiveIndex(e.index)} responsiveOptions={responsiveOptions} numVisible={5}
    item={itemTemplate} thumbnail={thumbnailTemplate} style={{ maxWidth: '640px' }} />
