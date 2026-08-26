<Mention value={value} onChange={(e) => setValue(e.target.value)} trigger={['@', '#']} suggestions={multipleSuggestions} onSearch={onMultipleSearch}
    field={['nickname']} placeholder="Enter @ to mention people, # to mention tag" itemTemplate={multipleItemTemplate} rows={5} cols={40} />
