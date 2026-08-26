<AutoComplete value={selectedCity} onChange={(e) => setSelectedCity(e.value)} suggestions={filteredCities} completeMethod={search}
        field="label" optionGroupLabel="label" optionGroupChildren="items" optionGroupTemplate={groupedItemTemplate} placeholder="Hint: type 'a'" />
