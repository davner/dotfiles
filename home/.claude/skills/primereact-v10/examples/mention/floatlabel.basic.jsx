<span className="p-float-label">
    <Mention inputId="newpost" value={value} onChange={(e) => setValue(e.target.value)} suggestions={suggestions} onSearch={onSearch} 
        field="nickname" rows={5} cols={40} itemTemplate={itemTemplate} />
    <label htmlFor="newpost">New Post</label>
</span>
