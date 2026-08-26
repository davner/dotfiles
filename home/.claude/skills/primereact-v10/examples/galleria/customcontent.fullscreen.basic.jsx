<Galleria ref={galleria} value={images} numVisible={7} style={{ maxWidth: '850px' }}
    activeIndex={activeIndex} onItemChange={(e) => setActiveIndex(e.index)}
    circular fullScreen showItemNavigators showThumbnails={false} item={itemTemplate} thumbnail={thumbnailTemplate} />

<div className="grid" style={{ maxWidth: '400px' }}>
    {
        images && images.map((image, index) => {
            let imgEl = <img src={image.thumbnailImageSrc} onClick={
                () => {setActiveIndex(index); galleria.current.show()}
            } />
            return (
                <div className="col-3" key={index}>
                    {imgEl}
                </div>
            )
        })
    }
</div>
