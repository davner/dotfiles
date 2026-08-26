<AutoComplete field="name" value={selectedCountry} suggestions={filteredCountries}  
    completeMethod={search} onChange={(e) => setSelectedCountry(e.value)} itemTemplate={itemTemplate} panelFooterTemplate={panelFooterTemplate} selectedItemTemplate={selectedItemTemplate} />
