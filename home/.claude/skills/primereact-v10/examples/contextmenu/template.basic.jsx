<div className="card flex md:justify-content-center">
    <ul className="m-0 p-0 list-none border-1 surface-border border-round p-3 flex flex-column gap-2 w-full md:w-30rem">
        {products.map((product) => (
            <li
                key={product.id}
                className={`p-2 hover:surface-hover border-round border-1 border-transparent transition-all transition-duration-200 ${selectedId === product.id && 'border-primary'}`}
                onContextMenu={(e) => onRightClick(e, product.id)}
            >
                <div className="flex flex-wrap p-2 align-items-center gap-3">
                    <img className="w-4rem shadow-2 flex-shrink-0 border-round" src={`/images/product/${product.image}`} alt="product.name" />
                    <div className="flex-1 flex flex-column gap-1">
                        <span className="font-bold">{product.name}</span>
                        <div className="flex align-items-center gap-2">
                            <i className="pi pi-tag text-sm"></i>
                            <span>{product.category}</span>
                        </div>
                    </div>
                    <span className="font-bold text-900 ml-5">{product.price}</span>
                </div>
            </li>
        ))}
    </ul>
    <ContextMenu model={items} ref={cm} breakpoint="767px" onHide={() => setSelectedId(undefined)} />
</div>
