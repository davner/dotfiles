<span className="p-float-label">
    <AutoComplete inputId="ac" value={value} suggestions={items} completeMethod={search} onChange={(e) => setValue(e.value)} />
    <label htmlFor="ac">Float Label</label>
</span>
